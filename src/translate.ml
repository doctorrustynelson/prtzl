open Ast
open Ccode

module StringMap = Map.Make(String)

exception ParseError of string

let rec comparelist v1 v2 = match v1, v2 with
  [], []       -> true
| [], _
| _, []        -> false
| x::xs, y::ys -> x = y && comparelist xs ys

let standardLibrary = [ ["print_number";  "Void";   "Number"]; 
                        ["print_string";  "Void";   "String"];
                        ["print_vertex";  "Void";   "Vertex"];
                        ["print_edge";    "Void";   "Edge"  ];
                        ["link";          "Number"; "Vertex"; "Vertex"; "Number"];
                        ["bi_link";       "Number"; "Vertex"; "Vertex"; "Number"];
                        ["list_length";   "Number"; "List"  ];
                        ["cmp";           "Number"; "String"; "String"];
                      ]

let string_of_datatype = function
    Number -> "Number"
  | String -> "String"
  | Vertex -> "Vertex"
  | Edge   -> "Edge"
  | Void   -> "Void"  
  | List   -> "List"

(* expr returns tuple (datatype, cstmt list) *)
(* e = expression 
   sm = main variable map
   fm = function map
   lm = local variable map
   fname = function name *)
let rec expr (e, sm, fm, lm, fname) = 
      match e with
      Str i -> ("String", [Strg i])
        | Id s ->  if(StringMap.mem s sm) then ((StringMap.find s sm), [Id s])
                else (if (StringMap.mem fname lm) then ( let lmap = (StringMap.find fname lm) in if(StringMap.mem s lmap) then ((StringMap.find s lmap), [Id s]) else raise (ParseError (s ^ " not declare")) )
                      else raise (ParseError (fname ^ " not declare")) )
        | Int i -> ("Number", [Int i])
        | Num n -> ("Number", [Numb n])
        | Vertex(label) -> ("Vertex", [Vertex label])
        | Edge(label)   -> ("Edge", [Edge label])
        | Binop (e1, op, e2) -> if(fst (expr(e1, sm, fm, lm, fname)) = fst (expr(e2, sm, fm, lm, fname)) )
                      then ((fst (expr(e1, sm, fm, lm, fname))), [Binop (expr (e1, sm, fm, lm, fname) , op, expr (e2, sm, fm, lm, fname) )])
                      else raise (ParseError "type not match") 
        | Assign (id, value) -> if(fst (expr(value, sm, fm, lm, fname) ) = "" ) (*List type work around*)
                      then ( fst (expr(value, sm, fm, lm, fname) ), [Assign (id, (expr(value, sm, fm, lm, fname) ))])
                      else(
                        if(fname = "")(*main*)
                        then(
                          if(fst (expr(value, sm, fm, lm, fname) ) = (StringMap.find id sm) )
                          then ( fst (expr(value, sm, fm, lm, fname) ), [Assign (id, (expr(value, sm, fm, lm, fname) ))])
                          else raise (ParseError "type not match")
                        )
                        else(
                          if(fst (expr(value, sm, fm, lm, fname) ) = (StringMap.find id (StringMap.find fname lm) ) )
                          then ( fst (expr(value, sm, fm, lm, fname) ), [Assign (id, (expr(value, sm, fm, lm, fname) ))])
                          else raise (ParseError "type not match")
                        )
                      )
        | Keyword k -> ("Void", [Keyword k])
        | Not(n) -> (fst (expr (n, sm, fm, lm, fname)), [Not (snd (expr (n, sm, fm, lm, fname) ))])
        | Neg(n) -> (fst (expr (n, sm, fm, lm, fname)), [Neg (snd (expr (n, sm, fm, lm, fname) ))])
        | Call(s, el) ->  if(StringMap.mem s fm) then
                            (if( comparelist (List.tl (StringMap.find s fm) ) (List.map (fun x -> fst (expr(x,sm, fm, lm, fname)) ) el ) ) 
                            then ( (List.hd (StringMap.find s fm) ), [Call (s, (List.concat (List.map (fun x -> snd (expr(x,sm, fm, lm, fname)) ) el)))])
                            else raise (ParseError ("In function "^s^", arguement types do not match") ))
                          else raise (ParseError ("function " ^ s ^ " not defined") )
        | List(el) -> ("List", [List ("", (List.concat (List.map (fun x ->  snd (expr (x, sm, fm, lm, fname) ) ) el)))])
        | Mem(id, e) -> ("",[Mem (id, (snd (expr (e, sm, fm, lm, fname) ) ) )])
        | ListAssign(id, i, e) -> ("", [ListAssign (id, (snd (expr (i, sm, fm, lm, fname) ) ), (snd (expr (e, sm, fm, lm, fname) ) ) )])
        | Insert(e) ->  if((fst (expr (e, sm, fm, lm, fname) ) ) = "String")
                        then ("Vertex", [Insert  (snd (expr (e, sm, fm, lm, fname) ) )])
                        else raise ( ParseError ("arguement of vertex insert has to be string") )
        | Query(e) ->   if((fst (expr (e, sm, fm, lm, fname) ) ) = "String")
                        then ("Vertex", [Query (snd (expr (e, sm, fm, lm, fname)))])
                        else raise ( ParseError ("arguement of vertex query has to be string") )
        | Delete(e) ->  if((fst (expr (e, sm, fm, lm, fname) ) ) = "String")
                        then ("Number", [Delete (snd (expr (e, sm, fm, lm, fname)))])
                        else raise ( ParseError ("arguement of vertex delete has to be string") )
        | Property(id, p) -> if(StringMap.mem id sm || (StringMap.mem id (StringMap.find fname lm)) ) 
                             then(match p with 
                               "in"   -> ("List", [Property (id, p)]) 
                             | "out"  -> ("List", [Property (id, p)])
                             | "in_degree"  -> ("Number", [Property(id, p)])
                             | "out_degree" -> ("Number", [Property(id, p)])
                             | "weight" -> ("Number", [Property(id, p)])
                             | "to" -> ("List", [Property(id, p)])
                             | "from" -> ("List", [Property(id, p)])
                             | "src" -> ("Vertex", [Property(id, p)])
                             | "dest" -> ("Vertex", [Property(id, p)])
                             | _ -> ("", [Property(id, p)])
                             )
                             else raise (ParseError (id ^ " not declared"))
        | PropertyAssign(id, p, e) -> if(StringMap.mem id sm || (StringMap.mem id (StringMap.find fname lm)) ) 
                             then ("Void", [PropertyAssign (id, p, (snd (expr (e, sm, fm, lm, fname) ) ) )])
                             else raise (ParseError (id ^ " not declared"))
        | AddParen(e) -> ((fst (expr (e, sm, fm, lm, fname) ) ), [AddParen (snd (expr (e, sm, fm, lm, fname) ) )])
        | Noexpr -> ("Void", [])
    
(* stmt returns cstmt list *)
(* st = stmt 
   sm = main variable map
   fm = function map
   lm = local variable map
   fname = function name *)
let rec stmt (st, sm ,fm, lm, fname)  = 
      match st with
          Block sl     -> List.concat (List.map (fun x -> stmt (x,sm, fm, lm, fname) ) sl )
        | Expr e       -> snd(expr (e, sm, fm, lm, fname)) @ [Keyword ";"]
        | If (e1, e2, e3, e4) -> (match e3 with
                  [Block([])] -> (match e4 with 
                      [Block([])] -> [If (snd(expr (e1, sm, fm, lm, fname) ) )] @ [Then (stmt (Block(e2), sm, fm, lm, fname) )]
                    |   _ -> [If (snd (expr (e1, sm, fm, lm, fname) ) )] @ [Then (stmt (Block(e2), sm, fm, lm, fname) )] @ [Else (stmt (Block(e4), sm, fm, lm, fname) )] 
                  )
                |   (Elseif(e,s)) ::tail -> [If (snd (expr (e1, sm, fm, lm, fname) ) )] @ [Then (stmt (Block(e2), sm, fm, lm, fname) )] @ [Elseif ( (snd (expr (e, sm, fm, lm, fname))), stmt (Block(s), sm, fm, lm, fname) )] @ List.concat (List.map (fun x -> stmt (x,sm, fm, lm, fname) ) tail ) @ [Else (stmt (Block(e4), sm, fm, lm, fname) )]
                |   _ -> raise (ParseError "caught parse error in if")
                )(*[Keyword "if "] @ expr e1 @ stmt e2 @  List.concat (List.map stmt e3) @ stmt e4*)
        | Elseif(e, s) -> [Elseif ( (snd(expr (e, sm, fm, lm, fname) ) ), (stmt (Block(s), sm, fm, lm, fname) ))]
        | While(e, s) -> [While ( (snd (expr (e, sm, fm, lm, fname) ) ), (stmt (Block(s), sm, fm, lm, fname) ) )]
        | Return e     -> [Return ( snd (expr (e, sm, fm, lm, fname) ) ) ]

(* translates Ast.program to cstmt list *)
(* global = main vaiables 
   statements = main statements
   functions = function declarations *)
let translate (globals, statements, functions) =

  (* translate function declaration *)
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
      List.concat (List.map (fun x -> [Datatype x.vtype] @ snd(expr (x.value, sm, fm, lm, fdecl.fname))) fdecl.locals ) @
      (stmt ((Block fdecl.body), sm, fm, lm, fname)) @ [Keyword "\r\n}\r\n"](*@  (* Body *)
      [Ret 0]   (* Default = return 0 *)*)

  (* translatre main statements *)
  and translatestm (stm, sm, fm, lm, fname) = 
    stmt ((Block stm), sm, fm, lm, fname)

  (* translate main variables *)
  and translatestg (glob, sm, fm, lm, fname) = 
    [Datatype glob.vtype] @ snd(expr (glob.value, sm, fm, lm, fname))

  (* create stringMap for main variables to their types *)
  and map varlist = 
    List.fold_left 
      (fun m var -> if(StringMap.mem var.vname m) then raise (ParseError ("variable " ^ var.vname ^ " already declared in main"))
      else StringMap.add var.vname (string_of_datatype var.vtype) m) StringMap.empty varlist

  (* create StringMap for functions to their return types and arguement types *)
  and functionmap fdecls =
    let fmap = List.fold_left
      (fun m fdecl -> if(StringMap.mem fdecl.fname m) then raise (ParseError ("function " ^ fdecl.fname ^ " already declared") )
      else StringMap.add fdecl.fname ([string_of_datatype fdecl.rtype] @ (List.map (fun x -> (string_of_datatype x.ftype) ) fdecl.formals) ) m) StringMap.empty fdecls
    in  List.fold_left (fun m x -> StringMap.add (List.hd x) (List.tl x) m) fmap standardLibrary

  (* create StringMap for functions to map its local variables and types *)
  and localmap fdecls = 
    (* add formals first and the local variables *)
    let perfunction formals = List.fold_left
        (fun m formal -> if(StringMap.mem formal.frname m) then raise (ParseError ("formal arguement " ^ formal.frname ^ " already declared") ) 
        else StringMap.add formal.frname (string_of_datatype formal.ftype) m) StringMap.empty formals
    in
    List.fold_left
      (fun m fdecl -> if(StringMap.mem fdecl.fname m) then raise (ParseError ("function " ^ fdecl.fname ^ " already declared") )
      else StringMap.add fdecl.fname 

      (List.fold_left (fun m local -> if(StringMap.mem local.vname m) then raise (ParseError ("local variable " ^ local.vname ^" already declared in " ^ fdecl.fname) )
      else StringMap.add local.vname (string_of_datatype local.vtype) m) (perfunction fdecl.formals)  fdecl.locals)

      m) StringMap.empty fdecls
      

  in [Keyword "#include \"prtzl.h\"\r\nstruct graph* g;\r\n"] @
     List.concat (List.map (fun x -> translatefunc (x, StringMap.empty, (functionmap functions), (localmap functions), x.fname ) ) (List.rev functions) ) @
     [Main] @ 
     List.concat (List.map (fun x -> translatestg (x, (map globals), (functionmap functions), StringMap.empty, "" ) ) (List.rev globals) ) @ 
     translatestm ((List.rev statements), (map globals), (functionmap functions), StringMap.empty, "" ) 
     @ [Endmain]

(* convert cstmt to c code *)
let rec string_of_ccode (ty, cs) = 
  match cs with
  Main -> "int main() {\r\ng=init_graph();\r\n"
  | Endmain -> "\r\n\t return 0; \r\n}\r\n" 
  | Strg(l) -> l
  | Id(s) -> s
  | Numb(n) -> (string_of_float n)
  | Int(i) -> (string_of_int i)
  | Vertex(l) -> l
  | Edge(l) -> l
  | Keyword(k) -> k
  | Datatype(t) -> (match t with 
            Number  -> "double "
          |   String  -> "char* "
          |   Vertex  -> "struct node* "
          |   Edge  -> "struct node* " 
          |   List  -> "struct list* "
          |   Void  -> "void ")
  | Binop((ty1,e1),op,(ty2,e2)) -> (match op with
              Add   ->  if(ty1 = "Number" && ty2 = "Number") then
                          (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty1, x) ) e1) )
                          ^ " + " ^ 
                          (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty2, x) ) e2) )
                        else raise (ParseError "+ operator only applies to Number" )
          |   Sub   ->  if(ty1 = "Number" && ty2 = "Number") then
                          (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty1, x) ) e1) ) 
                          ^ " - " ^ 
                          (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty2, x) ) e2) )
                        else raise (ParseError "- operator only applies to Number" )
          |   Mul   ->  if(ty1 = "Number" && ty2 = "Number") then
                          (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty1, x) ) e1) ) 
                          ^ " * " ^ 
                          (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty2, x) ) e2) )
                        else raise (ParseError "* operator only applies to Number" )
          |   Div   ->  if(ty1 = "Number" && ty2 = "Number") then
                          (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty1, x) ) e1) ) 
                          ^ " / "  ^ 
                          (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty2, x) ) e2) )
                        else raise (ParseError "/ operator only applies to Number" )
          |   Equal ->  if(ty1 = "Number" && ty2 = "Number") then
                          (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty1, x) ) e1) ) 
                          ^ " == " ^ 
                          (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty2, x) ) e2) )
                        else raise (ParseError "== operator only applies to Number" )
          |   Neq   ->  if(ty1 = "Number" && ty2 = "Number") then
                          (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty1, x) ) e1) ) 
                          ^ " != " ^ 
                          (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty2, x) ) e2) )
                        else raise (ParseError "!= operator only applies to Number" )
          |   Less  ->  if(ty1 = "Number" && ty2 = "Number") then
                          (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty1, x) ) e1) ) 
                          ^ " < " ^ 
                          (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty2, x) ) e2) )
                        else raise (ParseError "< operator only applies to Number" )
          |   Leq   ->  if(ty1 = "Number" && ty2 = "Number") then
                          (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty1, x) ) e1) ) 
                          ^ " <= " ^ 
                          (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty2, x) ) e2) )
                        else raise (ParseError "<= operator only applies to Number" )
          |   Greater ->  if(ty1 = "Number" && ty2 = "Number") then
                            (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty1, x) ) e1) ) 
                            ^ " > " ^ 
                            (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty2, x) ) e2) )
                          else raise (ParseError "> operator only applies to Number" )
          |   Geq   ->  if(ty1 = "Number" && ty2 = "Number") then
                          (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty1, x) ) e1) ) 
                          ^ " >= "  ^ 
                          (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty2, x) ) e2) )
                        else raise (ParseError ">= operator only applies to Number" )
          |   Concat  ->  if(ty1 = "String" && ty2 = "String") then
                            "cat(" ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty1, x) ) e1) ) 
                            ^ ", " ^ 
                            (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty2, x) ) e2) ) ^ ")"
                          else raise (ParseError "^ operator only applies to constant strings" )
        )
  | Assign(id, (ty,value))  -> (match value with
            []      -> id ^ ";"
          | [Strg _]  -> id ^ " = " ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) value) ) ^ ";"
          | [Id _]    -> id ^ " = " ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) value) ) ^ ";"
          | [Int _]   -> id ^ " = " ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) value) ) ^ ";"
          | [Numb _]  -> id ^ " = " ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) value) ) ^ ";"
          |   [Vertex _]  -> id ^ ";"
          |   [Edge _]  -> id ^ ";"
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
          | [Property _]  -> id ^ " = " ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) value) ) ^ ";"
          |   _ -> raise (ParseError "caught parse error in Assign")
          )
  | Not(cl)   -> "!(" ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) cl)) ^ ")"
  | Neg(cl)   -> "-(" ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) cl)) ^ ")"
  | Call(s, cl) -> s ^ "(" ^ (List.fold_left (fun x y -> match x with "" -> y | _ -> x^","^y) "" (List.map (fun x -> string_of_ccode (ty, x ) ) cl)) ^ ")"
  | List(id, cl)-> (List.fold_left (fun x y -> match x with "" -> y | _ -> x^","^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) cl))
  | Mem(id, e)  -> "list_get(" ^ id ^ ", " ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) e)) ^ ")"
  | ListAssign(id, i, e) -> "list_set(" ^ id ^ ", " ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) e)) ^ ", " ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) i)) ^ ")"
  | If(s)     -> "if(" ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) s)) ^ ")"
  | Then(s)   -> "{\r\n\t" ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) s)) ^ "\r\n}"
  | Else(s)   -> "else\r\n{\r\n\t" ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) s)) ^ "\r\n}"
  | Elseif(e, s)-> "else if(" ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) e)) ^ ")\r\n{\r\n\t" ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) s)) ^ "\r\n}"
  | While(e, s) -> "while(" ^(List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) e)) ^ ")" ^
             "{\r\n\t" ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) s)) ^ "\r\n}"
  | Return(s)   -> "return " ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) s)) ^ ";"
  | Insert(e)   -> "insert_vertex(g, " ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) e)) ^ ")"
  | Query(e)  -> "query_vertex(g, " ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) e)) ^ ")"
  | Delete(e)   -> "delete_vertex(g, " ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) e)) ^ ")"
  | Property(id, p) -> "get_node_property("^ id ^", \"" ^ p ^ "\")"
  | PropertyAssign(id, p, e) -> "put_node_property(" ^ id ^ ", \"" ^ p ^ "\", " ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) e)) ^ ")"
  | AddParen(e) -> "(" ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) e)) ^ ")"


  (*| Formal(f) -> (List.fold_left (fun x y -> x^y) "" (List.map string_of_ccode f))*)
(*let _ =
  let lexbuf = Lexing.from_channel stdin in
  let program = Parser.program Scanner.token lexbuf in
  (*Translate.translate program*)
  let result = translate program in 
    (List.iter (fun x -> print_endline (string_of_ccode x)) result)*)
  

