open Ast
open Ccode

module StringMap = Map.Make(String)

exception ParseError of string

let string_of_datatype = function
  	Number -> "Number"
  | String -> "String"
  | Vertex -> "Vertex"
  | Edge   -> "Edge"
  | Void   -> "Void"	
  | List   -> "List"


let rec expr (e, sm, fm) = 
			match e with
			Str i -> ("String", [Strg i])
	      | Id s ->  if(StringMap.mem s sm) then ((StringMap.find s sm), [Id s])
	      			 else raise (ParseError (s ^ " not declare"))
	      | Int i -> ("Number", [Int i])
	      | Num n -> ("Number", [Numb n])
	      | Vertex(label) -> ("Vertex", [Vertex label])
	      | Binop (e1, op, e2) -> if(fst (expr(e1,sm,fm)) = fst (expr(e2,sm,fm)) )
	      						  then ((fst (expr(e1,sm,fm))), [Binop (expr (e1,sm,fm) , op, expr (e2, sm, fm) )])
	      						  else raise (ParseError "type not match") 
	      | Assign (id, value) -> if(fst (expr(value, sm, fm) ) = (StringMap.find id sm) )
	      						  then ( fst (expr(value, sm, fm) ), [Assign (id, (expr(value, sm, fm) ))])
	      						  else raise (ParseError "type not match")
	      | Keyword k -> ("Void", [Keyword k])
	      | Not(n) -> (fst (expr (n, sm, fm)), [Not (snd (expr (n, sm, fm) ))])
	      | Neg(n) -> (fst (expr (n, sm, fm)), [Neg (snd (expr (n, sm, fm) ))])
	      | Call(s, el) -> ( (List.hd (StringMap.find s fm) ), [Call (s, (List.concat (List.map (fun x -> [{ty=fst (expr(x,sm, fm)); value=x}] ) el)))])
	      | List(el) -> ("List", [List ("", (List.concat (List.map (fun x ->  snd (expr (x, sm, fm) ) ) el)))])
	      | Mem(id, i) -> ("Void",[Mem (id, i)])
	      | Insert(e) -> ("Vertex", [Insert  (snd (expr (e, sm, fm) ) )])
	      | Query(e) -> ("Vertex", [Query (snd (expr (e, sm, fm)))])
	      | Delete(e) -> ("Number", [Delete (snd (expr (e, sm, fm)))])
	      | Noexpr -> ("Void", [])

let rec stmt (st, sm ,fm)  = 
			match st with
			Block sl     -> List.concat (List.map (fun x -> stmt (x,sm, fm) ) sl )
	      | Expr e       -> snd(expr (e, sm, fm)) @ [Keyword ";"]
	      | If (e1, e2, e3, e4) -> (match e3 with
	      					[] -> (match e4 with 
			      					Block([]) -> [If (snd(expr (e1, sm, fm) ) )] @ [Then (stmt (e2, sm, fm) )]
			      				|   _ -> [If (snd (expr (e1, sm, fm) ) )] @ [Then (stmt (e2, sm, fm) )] @ [Else (stmt (e4, sm, fm) )]	
			      			)
	      				| 	(Elseif(e,s)) ::tail -> [If (snd (expr (e1, sm, fm) ) )] @ [Then (stmt (e2, sm, fm) )] @ [Elseif ( (snd (expr (e, sm, fm))), stmt (s, sm, fm) )] @ List.concat (List.map (fun x -> stmt (x,sm, fm) ) tail ) @ [Else (stmt (e4, sm, fm) )]
	      				|   _ -> raise (ParseError "caught parse error")
	      				)(*[Keyword "if "] @ expr e1 @ stmt e2 @  List.concat (List.map stmt e3) @ stmt e4*)
	      | Elseif(e, s) -> [Elseif ( (snd(expr (e, sm, fm) ) ), (stmt (s, sm, fm) ))]
	      | While(e, s) -> [While ( (snd (expr (e, sm, fm) ) ), (stmt (s, sm, fm) ))]
	      | Return e     -> [Return ( snd (expr (e, sm, fm) ) ) ]


let translate (globals, statements, functions) =

	let translatefunc (fdecl, sm, fm) =
		let rec arg = function
			  [] -> []
			| [a] -> [Datatype a.ftype] @ [Id a.fname]
			| hd::tl -> [Datatype hd.ftype] @ [Id hd.fname] @ [Keyword ", "] @ arg tl
		in
	    [Datatype fdecl.rtype] @ [Id fdecl.fname] @ 
	    [Keyword "("] @ 
	    arg fdecl.formals @ 
	    [Keyword ")\r\n{\r\n"] @
	    stmt ((Block fdecl.body), sm, fm) @ [Keyword "\r\n}\r\n"](*@  (* Body *)
	    [Ret 0]   (* Default = return 0 *)*)
	and translatestm (stm, sm, fm) = 
		stmt ((Block stm), sm, fm)

	and translatestg (glob, sm, fm) = 
		[Datatype glob.vtype] @ snd(expr (glob.value, sm, fm))

	and map varlist = 
		List.fold_left 
			(fun m var -> if(StringMap.mem var.vname m) then raise (ParseError (var.vname ^ " already declared"))
			else StringMap.add var.vname (string_of_datatype var.vtype) m) StringMap.empty varlist

	and functionmap fdecls =
		List.fold_left
			(fun m fdecl -> if(StringMap.mem fdecl.fname m) then raise (ParseError ("function " ^ fdecl.fname ^ " already declared") )
			else StringMap.add fdecl.fname ([string_of_datatype fdecl.rtype] @ (List.map (fun x -> (string_of_datatype x.ftype) ) fdecl.formals) ) m) StringMap.empty fdecls

	in (*map globals; (List.concat (List.map (fun x -> x.locals) functions)));*)
	   List.concat (List.map (fun x -> translatefunc (x, (map globals), (functionmap functions) ) ) functions ) @
	   [Main] @ 
	   List.concat (List.map (fun x -> translatestg (x, (map globals), (functionmap functions) ) ) globals) @ 
	   translatestm (statements, (map globals), (functionmap functions) ) 
	   @ [Endmain]


let rec string_of_ccode (ty, cs) = 
	match cs with
	Main -> "int main() { \r\n"
  | Endmain -> "\r\n\t return 0; \r\n}\r\n"	
  | Strg(l) -> l
  | Id(s) -> s
  | Numb(n) -> (string_of_float n)
  | Int(i) -> (string_of_int i)
  | Vertex(l) -> l
  | Keyword(k) -> k
  | Datatype(t) -> (match t with 
  					Number 	-> "double "
  				| 	String 	-> "char* "
  				| 	Vertex 	-> "struct node* "
  				| 	List 	-> "struct list* ")
  | Binop((ty1,e1),op,(ty2,e2)) -> (match op with
  					Add 	-> (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty1, x) ) e1) )
  							   ^ " + " ^ 
  							   (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty2, x) ) e2) )
  				| 	Sub 	-> (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty1, x) ) e1) ) 
  							   ^ " - " ^ 
  							   (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty2, x) ) e2) )
  				| 	Mul 	-> (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty1, x) ) e1) ) 
  							   ^ " * " ^ 
  							   (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty2, x) ) e2) )
  				| 	Div 	-> (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty1, x) ) e1) ) 
  							   ^ " / "  ^ 
  							   (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty2, x) ) e2) )
  				| 	Equal 	-> (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty1, x) ) e1) ) 
  							   ^ " == " ^ 
  							   (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty2, x) ) e2) )
  				| 	Neq 	-> (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty1, x) ) e1) ) 
  							   ^ " != " ^ 
  							   (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty2, x) ) e2) )
  				| 	Less 	-> (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty1, x) ) e1) ) 
  							   ^ " < " ^ 
  							   (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty2, x) ) e2) )
  				| 	Leq 	-> (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty1, x) ) e1) ) 
  							   ^ " <= " ^ 
  							   (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty2, x) ) e2) )
  				| 	Greater -> (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty1, x) ) e1) ) 
  							   ^ " > " ^ 
  							   (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty2, x) ) e2) )
  				| 	Geq 	-> (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty1, x) ) e1) ) 
  							   ^ " >= "  ^ 
  							   (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty2, x) ) e2) )
  				| 	Concat 	-> (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty1, x) ) e1) ) 
  							   ^ " ^ " ^ 
  							   (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty2, x) ) e2) )
  			)
  | Assign(id, (ty,value)) 	-> (match value with
  					[]  		-> id ^ ";"
  				|	[Strg _] 	-> id ^ " = " ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) value) ) ^ ";"
  				|	[Id _] 		-> id ^ " = " ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) value) ) ^ ";"
  				|	[Int _] 	-> id ^ " = " ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) value) ) ^ ";"
  				|	[Numb _] 	-> id ^ " = " ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) value) ) ^ ";"
  				|   [Vertex _] 	-> id ^ ";"
  				|	[Keyword _] -> id ^ " = " ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) value) ) ^ ";"
  				|	[Not _] 	-> id ^ " = " ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) value) ) ^ ";"
  				|	[Neg _] 	-> id ^ " = " ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) value) ) ^ ";"
  				|	[Call _] 	-> id ^ " = " ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) value) ) ^ ";"
  				| 	[List (i, e)] -> id ^ " = list_init();\r\n"^ (List.fold_left (fun x y -> x^"list_add("^id^", "^y^");\r\n") "" (List.map (fun x -> string_of_ccode (ty, x) ) e)) 
  				|   [Binop _] 	-> id ^ " = " ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) value) ) ^ ";"
  				|   [Mem _] 	-> id ^ " = " ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) value) ) ^ ";"
  				|  	[Insert _] 	-> id ^ " = " ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) value) ) ^ ";"
  				| 	[Query _] 	-> id ^ " = " ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) value) ) ^ ";"
  				| 	[Delete _] 	-> id ^ " = " ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) value) ) ^ ";"
  				|   _ -> raise (ParseError "caught parse error")
  				)
  | Not(cl) 	-> "!(" ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) cl)) ^ ")"
  | Neg(cl) 	-> "-(" ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) cl)) ^ ")"
  | Call(s, cl) -> s ^ "(" ^ (List.fold_left (fun x y -> match x with "" -> y | _ -> x^","^y) "" (List.map (fun x -> string_of_ccode (ty, List.hd (snd (expr (x.value, StringMap.empty, StringMap.empty) ) ) ) ) cl)) ^ ");"
  | List(id, cl)-> (List.fold_left (fun x y -> match x with "" -> y | _ -> x^","^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) cl))
  | Mem(id, i) 	-> "list_get(" ^ id ^ ", " ^ string_of_int i ^ ")"
  | If(s) 		-> "if(" ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) s)) ^ ")"
  | Then(s) 	-> "{\r\n\t" ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) s)) ^ "\r\n}"
  | Else(s) 	-> "else\r\n{\r\n\t" ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) s)) ^ "\r\n}"
  | Elseif(e, s)-> "elseif(" ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) e)) ^ ")\r\n{\r\n\t" ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) s)) ^ "\r\n}"
  | While(e, s) -> "while(" ^(List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) e)) ^ ")" ^
  				   "{\r\n\t" ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) s)) ^ "\r\n}"
  | Return(s) 	-> "return " ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) s)) ^ ";"
  | Insert(e) 	-> "insert_vertex(g, " ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) e)) ^ ");"
  | Query(e) 	-> "query_vertex(g, " ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) e)) ^ ");"
  | Delete(e) 	-> "delete_vertex(g, " ^ (List.fold_left (fun x y -> x^y) "" (List.map (fun x -> string_of_ccode (ty, x) ) e)) ^ ");"


  (*| Formal(f) -> (List.fold_left (fun x y -> x^y) "" (List.map string_of_ccode f))*)
(*let _ =
  let lexbuf = Lexing.from_channel stdin in
  let program = Parser.program Scanner.token lexbuf in
  (*Translate.translate program*)
  let result = translate program in 
    (List.iter (fun x -> print_endline (string_of_ccode x)) result)*)
  

