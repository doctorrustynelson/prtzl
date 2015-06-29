open Ast
open Ccode

module StringMap = Map.Make(String)

exception ParseError of string

let rec comparelist v1 v2 = match v1, v2 with
  [], []       -> true
| [], _
| _, []        -> false
| x::xs, y::ys -> x = y && comparelist xs ys

let string_of_datatype = function
    Number -> "Number"
  | String -> "String"
  | Vertex -> "Vertex"
  | Edge   -> "Edge"
  | Void   -> "Void"  
  | List   -> "List"


let rec expr (e, sm, fm, lm, fname) = 
      match e with
      Str i -> ("String", [Strg i])
        | Id s ->  if(StringMap.mem s sm) then ((StringMap.find s sm), [Id s])
                else (if (StringMap.mem fname lm) then ( let lmap = (StringMap.find fname lm) in if(StringMap.mem s lmap) then ((StringMap.find s lmap), [Id s]) else raise (ParseError (s ^ " not declare")) )
                      else raise (ParseError (fname ^ " not declare")) )
        | Int i -> ("Number", [Int i])
        | Num n -> ("Number", [Numb n])
        | Vertex(label) -> ("Vertex", [Vertex label])
        | Binop (e1, op, e2) -> if(fst (expr(e1, sm, fm, lm, fname)) = fst (expr(e2, sm, fm, lm, fname)) )
                      then ((fst (expr(e1, sm, fm, lm, fname))), [Binop (expr (e1, sm, fm, lm, fname) , op, expr (e2, sm, fm, lm, fname) )])
                      else raise (ParseError "type not match") 
        | Assign (id, value) -> if(fst (expr(value, sm, fm, lm, fname) ) = "" ) (*List type work around*)
                      then ( fst (expr(value, sm, fm, lm, fname) ), [Assign (id, (expr(value, sm, fm, lm, fname) ))])
                      else(
                        if(fst (expr(value, sm, fm, lm, fname) ) = (StringMap.find id sm) )
                        then ( fst (expr(value, sm, fm, lm, fname) ), [Assign (id, (expr(value, sm, fm, lm, fname) ))])
                        else raise (ParseError "type not match")
                      )
        | Keyword k -> ("Void", [Keyword k])
        | Not(n) -> (fst (expr (n, sm, fm, lm, fname)), [Not (snd (expr (n, sm, fm, lm, fname) ))])
        | Neg(n) -> (fst (expr (n, sm, fm, lm, fname)), [Neg (snd (expr (n, sm, fm, lm, fname) ))])
        | Call(s, el) -> if( comparelist (List.tl (StringMap.find s fm) ) (List.map (fun x -> fst (expr(x,sm, fm, lm, fname)) ) el ) ) 
                  then ( (List.hd (StringMap.find s fm) ), [Call (s, (List.concat (List.map (fun x -> snd (expr(x,sm, fm, lm, fname)) ) el)))])
                  else raise (ParseError "arguement types do not match")
        | List(el) -> ("List", [List ("", (List.concat (List.map (fun x ->  snd (expr (x, sm, fm, lm, fname) ) ) el)))])
        | Mem(id, i) -> ("",[Mem (id, i)])
        | ListAssign(id, i, e) -> ("", [ListAssign (id, i, (snd (expr (e, sm, fm, lm, fname) ) ) )])
        | Insert(e) -> ("Vertex", [Insert  (snd (expr (e, sm, fm, lm, fname) ) )])
        | Query(e) -> ("Vertex", [Query (snd (expr (e, sm, fm, lm, fname)))])
        | Delete(e) -> ("Number", [Delete (snd (expr (e, sm, fm, lm, fname)))])
        | Noexpr -> ("Void", [])

let rec stmt (st, sm ,fm, lm, fname)  = 
      match st with
      Block sl     -> List.concat (List.map (fun x -> stmt (x,sm, fm, lm, fname) ) sl )
        | Expr e       -> snd(expr (e, sm, fm, lm, fname)) @ [Keyword ";"]
        | If (e1, e2, e3, e4) -> (match e3 with
                  [] -> (match e4 with 
                      Block([]) -> [If (snd(expr (e1, sm, fm, lm, fname) ) )] @ [Then (stmt (e2, sm, fm, lm, fname) )]
                    |   _ -> [If (snd (expr (e1, sm, fm, lm, fname) ) )] @ [Then (stmt (e2, sm, fm, lm, fname) )] @ [Else (stmt (e4, sm, fm, lm, fname) )] 
                  )
                |   (Elseif(e,s)) ::tail -> [If (snd (expr (e1, sm, fm, lm, fname) ) )] @ [Then (stmt (e2, sm, fm, lm, fname) )] @ [Elseif ( (snd (expr (e, sm, fm, lm, fname))), stmt (s, sm, fm, lm, fname) )] @ List.concat (List.map (fun x -> stmt (x,sm, fm, lm, fname) ) tail ) @ [Else (stmt (e4, sm, fm, lm, fname) )]
                |   _ -> raise (ParseError "caught parse error")
                )(*[Keyword "if "] @ expr e1 @ stmt e2 @  List.concat (List.map stmt e3) @ stmt e4*)
        | Elseif(e, s) -> [Elseif ( (snd(expr (e, sm, fm, lm, fname) ) ), (stmt (s, sm, fm, lm, fname) ))]
        | While(e, s) -> [While ( (snd (expr (e, sm, fm, lm, fname) ) ), (stmt (s, sm, fm, lm, fname) ))]
        | Return e     -> [Return ( snd (expr (e, sm, fm, lm, fname) ) ) ]


let translate (globals, statements, functions) =

  let translatefunc (fdecl, sm, fm, lm, fname) =
    let rec arg = function
        [] -> []
      | [a] -> [Datatype a.ftype] @ [Id a.frname]
      | hd::tl -> [Datatype hd.ftype] @ [Id hd.frname] @ [Keyword ", "] @ arg tl
    in
      [Datatype fdecl.rtype] @ [Id fdecl.fname] @ 
      [Keyword "("] @ 
      arg fdecl.formals @ 
      [Keyword ")\r\n{\r\n"] @
      stmt ((Block fdecl.body), sm, fm, lm, fname) @ [Keyword "\r\n}\r\n"](*@  (* Body *)
      [Ret 0]   (* Default = return 0 *)*)
  and translatestm (stm, sm, fm, lm, fname) = 
    stmt ((Block stm), sm, fm, lm, fname)

  and translatestg (glob, sm, fm, lm, fname) = 
    [Datatype glob.vtype] @ snd(expr (glob.value, sm, fm, lm, fname))

  and map varlist = 
    List.fold_left 
      (fun m var -> if(StringMap.mem var.vname m) then raise (ParseError ("global variable " ^ var.vname ^ " already declared"))
      else StringMap.add var.vname (string_of_datatype var.vtype) m) StringMap.empty varlist

  and functionmap fdecls =
    List.fold_left
      (fun m fdecl -> if(StringMap.mem fdecl.fname m) then raise (ParseError ("function " ^ fdecl.fname ^ " already declared") )
      else StringMap.add fdecl.fname ([string_of_datatype fdecl.rtype] @ (List.map (fun x -> (string_of_datatype x.ftype) ) fdecl.formals) ) m) StringMap.empty fdecls

  and localmap fdecls = 
    let perfunction formals = List.fold_left
        (fun m formal -> if(StringMap.mem formal.frname m) then raise (ParseError ("formal arguement " ^ formal.frname ^ " already declared") ) 
        else StringMap.add formal.frname (string_of_datatype formal.ftype) m) StringMap.empty formals
    in
    List.fold_left
      (fun m fdecl -> if(StringMap.mem fdecl.fname m) then raise (ParseError ("function " ^ fdecl.fname ^ " already declared") )
      else StringMap.add fdecl.fname 

      (List.fold_left (fun m local -> if(StringMap.mem local.vname m) then raise (ParseError ("local variable " ^ local.vname ^" already declared") )
      else StringMap.add local.vname (string_of_datatype local.vtype) m) (perfunction fdecl.formals)  fdecl.locals)

      m) StringMap.empty fdecls
      

  in (*map globals; (List.concat (List.map (fun x -> x.locals) functions)));*)
     List.concat (List.map (fun x -> translatefunc (x, (map globals), (functionmap functions), (localmap functions), x.fname ) ) functions ) @
     [Main] @ 
     List.concat (List.map (fun x -> translatestg (x, (map globals), (functionmap functions), StringMap.empty, "" ) ) (List.rev globals) ) @ 
     translatestm (statements, (map globals), (functionmap functions), StringMap.empty, "" ) 
     @ [Endmain]


let rec string_of_ccode (ty, cs) = 
  match cs with
  Main -> "#include \"prtzl.h\"\r\nstruct graph* g;\r\nint main() {\r\ng=init_graph();\r\n"
  | Endmain -> "\r\n\t return 0; \r\n}\r\n" 
  | Strg(l) -> l
  | Id(s) -> s
  | Numb(n) -> (string_of_float n)
  | Int(i) -> (string_of_int i)
  | Vertex(l) -> l
  | Keyword(k) -> k
  | Datatype(t) -> (match t with 
            Number  -> "double "
          |   String  -> "char* "
          |   Vertex  -> "struct node* "
          |   List  -> "struct list* ")
  | Binop((ty1,e1),op,(ty2,e2)) -> (match op with
            Add   -> (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty1, x) ) e1) )
                   ^ " + " ^ 
                   (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty2, x) ) e2) )
          |   Sub   -> (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty1, x) ) e1) ) 
                   ^ " - " ^ 
                   (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty2, x) ) e2) )
          |   Mul   -> (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty1, x) ) e1) ) 
                   ^ " * " ^ 
                   (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty2, x) ) e2) )
          |   Div   -> (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty1, x) ) e1) ) 
                   ^ " / "  ^ 
                   (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty2, x) ) e2) )
          |   Equal   -> (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty1, x) ) e1) ) 
                   ^ " == " ^ 
                   (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty2, x) ) e2) )
          |   Neq   -> (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty1, x) ) e1) ) 
                   ^ " != " ^ 
                   (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty2, x) ) e2) )
          |   Less  -> (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty1, x) ) e1) ) 
                   ^ " < " ^ 
                   (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty2, x) ) e2) )
          |   Leq   -> (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty1, x) ) e1) ) 
                   ^ " <= " ^ 
                   (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty2, x) ) e2) )
          |   Greater -> (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty1, x) ) e1) ) 
                   ^ " > " ^ 
                   (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty2, x) ) e2) )
          |   Geq   -> (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty1, x) ) e1) ) 
                   ^ " >= "  ^ 
                   (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty2, x) ) e2) )
          |   Concat  -> (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty1, x) ) e1) ) 
                   ^ " ^ " ^ 
                   (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty2, x) ) e2) )
        )
  | Assign(id, (ty,value))  -> (match value with
            []      -> id ^ ";"
          | [Strg _]  -> id ^ " = " ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) value) ) ^ ";"
          | [Id _]    -> id ^ " = " ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) value) ) ^ ";"
          | [Int _]   -> id ^ " = " ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) value) ) ^ ";"
          | [Numb _]  -> id ^ " = " ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) value) ) ^ ";"
          |   [Vertex _]  -> id ^ ";"
          | [Keyword _] -> id ^ " = " ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) value) ) ^ ";"
          | [Not _]   -> id ^ " = " ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) value) ) ^ ";"
          | [Neg _]   -> id ^ " = " ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) value) ) ^ ";"
          | [Call _]  -> id ^ " = " ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) value) ) ^ ";"
          |   [List (i, e)] -> id ^ " = list_init();\r\n"^ (List.fold_left (fun x y -> x^"list_add("^id^", "^y^");\r\n") "" (List.map (fun x -> string_of_ccode (ty, x) ) e)) 
          |   [Binop _]   -> id ^ " = " ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) value) ) ^ ";"
          |   [Mem _]   -> id ^ " = " ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) value) ) ^ ";"
          |   [Insert _]  -> id ^ " = " ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) value) ) ^ ";"
          |   [Query _]   -> id ^ " = " ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) value) ) ^ ";"
          |   [Delete _]  -> id ^ " = " ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) value) ) ^ ";"
          |   _ -> raise (ParseError "caught parse error")
          )
  | Not(cl)   -> "!(" ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) cl)) ^ ")"
  | Neg(cl)   -> "-(" ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) cl)) ^ ")"
  | Call(s, cl) -> s ^ "(" ^ (List.fold_left (fun x y -> match x with "" -> y | _ -> x^","^y) "" (List.map (fun x -> string_of_ccode (ty, x ) ) cl)) ^ ")"
  | List(id, cl)-> (List.fold_left (fun x y -> match x with "" -> y | _ -> x^","^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) cl))
  | Mem(id, i)  -> "list_get(" ^ id ^ ", " ^ string_of_int i ^ ")"
  | ListAssign(id, i, e) -> "list_set(" ^ id ^ ", " ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) e)) ^ ", " ^ string_of_int i ^ ")"
  | If(s)     -> "if(" ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) s)) ^ ")"
  | Then(s)   -> "{\r\n\t" ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) s)) ^ "\r\n}"
  | Else(s)   -> "else\r\n{\r\n\t" ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) s)) ^ "\r\n}"
  | Elseif(e, s)-> "elseif(" ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) e)) ^ ")\r\n{\r\n\t" ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) s)) ^ "\r\n}"
  | While(e, s) -> "while(" ^(List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) e)) ^ ")" ^
             "{\r\n\t" ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) s)) ^ "\r\n}"
  | Return(s)   -> "return " ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) s)) ^ ";"
  | Insert(e)   -> "insert_vertex(g, " ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) e)) ^ ")"
  | Query(e)  -> "query_vertex(g, " ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) e)) ^ ")"
  | Delete(e)   -> "delete_vertex(g, " ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) e)) ^ ")"


  (*| Formal(f) -> (List.fold_left (fun x y -> x^y) "" (List.map string_of_ccode f))*)
(*let _ =
  let lexbuf = Lexing.from_channel stdin in
  let program = Parser.program Scanner.token lexbuf in
  (*Translate.translate program*)
  let result = translate program in 
    (List.iter (fun x -> print_endline (string_of_ccode x)) result)*)
  

