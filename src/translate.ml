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


let rec expr (e, sm) = 
			match e with
			Str i -> ("String", [Strg i])
	      | Id s -> ((StringMap.find s sm), [Id s])
	      | Int i -> ("Number", [Int i])
	      | Num n -> ("Number", [Numb n])
	      | Binop (e1, op, e2) -> if(fst (expr(e1,sm)) = fst (expr(e2,sm)) )
	      						  then ((fst (expr(e1,sm))), [Binop (snd (expr (e1,sm) ), op, snd (expr (e2, sm) ))])
	      						  else raise (ParseError "type not match") 
	      | Assign (id, value) -> if(fst (expr(value, sm) ) = (StringMap.find id sm) )
	      						  then ( fst (expr(value, sm) ), [Assign (id, snd (expr(value, sm) ))])
	      						  else raise (ParseError "type not match")
	      | Keyword k -> ("Void", [Keyword k])
	      | Not(n) -> (fst (expr (n, sm)), [Not (snd (expr (n, sm) ))])
	      | Neg(n) -> (fst (expr (n, sm)), [Neg (snd (expr (n, sm) ))])
	      | Call(s, el) -> ("Void", [Call (s, (List.concat (List.map (fun x -> snd (expr (x, sm) ) ) el)))])
	      | List(el) -> ("List", [List ("", (List.concat (List.map (fun x ->  snd (expr (x, sm) ) ) el)))])
	      | Mem(id, i) -> ("Void",[Mem (id, i)])
	      | Noexpr -> ("Void", [])

let rec stmt (st, sm)  = 
			match st with
			Block sl     -> List.concat (List.map (fun x -> stmt (x,sm) ) sl )
	      | Expr e       -> snd(expr (e, sm)) @ [Keyword ";"]
	      | If (e1, e2, e3, e4) -> (match e3 with
	      					[] -> (match e4 with 
			      					Block([]) -> [If (snd(expr (e1, sm) ) )] @ [Then (stmt (e2, sm) )]
			      				|   _ -> [If (snd (expr (e1, sm) ) )] @ [Then (stmt (e2, sm) )] @ [Else (stmt (e4, sm) )]	
			      			)
	      				| 	(Elseif(e,s)) ::tail -> [If (snd (expr (e1, sm) ) )] @ [Then (stmt (e2, sm) )] @ [Elseif ( (snd (expr (e, sm))), stmt (s, sm) )] @ List.concat (List.map (fun x -> stmt (x,sm) ) tail ) @ [Else (stmt (e4, sm) )]
	      				|   _ -> raise (ParseError "caught parse error")
	      				)(*[Keyword "if "] @ expr e1 @ stmt e2 @  List.concat (List.map stmt e3) @ stmt e4*)
	      | Elseif(e, s) -> [Elseif ( (snd(expr (e, sm) ) ), (stmt (s, sm) ))]
	      | While(e, s) -> [While ( (snd (expr (e, sm) ) ), (stmt (s, sm) ))]
	      | Return e     -> [Return ( snd (expr (e, sm) ) ) ]


let translate (globals, statements, functions) =

	let translatefunc (fdecl, sm) =
		let rec arg = function
			  [] -> []
			| [a] -> [Datatype a.ftype] @ [Id a.fname]
			| hd::tl -> [Datatype hd.ftype] @ [Id hd.fname] @ [Keyword ", "] @ arg tl
		in
	    [Datatype fdecl.rtype] @ [Id fdecl.fname] @ 
	    [Keyword "("] @ 
	    arg fdecl.formals @ 
	    [Keyword ")\r\n{\r\n"] @
	    stmt ((Block fdecl.body), sm) @ [Keyword "\r\n}\r\n"](*@  (* Body *)
	    [Ret 0]   (* Default = return 0 *)*)
	and translatestm (stm, sm) = 
		stmt ((Block stm), sm)

	and translatestg (glob, sm) = 
		[Datatype glob.vtype] @ snd(expr (glob.value, sm))

	and map varlist = 
		List.fold_left 
			(fun m var -> if(StringMap.mem var.vname m) then raise (ParseError (var.vname ^ " already declared"))
			else StringMap.add var.vname (string_of_datatype var.vtype) m) StringMap.empty varlist

	in (*map globals; (List.concat (List.map (fun x -> x.locals) functions)));*)
	   List.concat (List.map (fun x -> translatefunc (x, (map globals) ) ) functions ) @
	   [Main] @ List.concat (List.map (fun x -> translatestg (x, (map globals) ) ) globals) @ translatestm (statements, (map globals)) @ [Endmain]


let rec string_of_ccode = function
	Main -> "int main() { \r\n"
  | Endmain -> "\r\n\t return 0; \r\n}\r\n"	
  | Strg(l) -> l
  | Id(s) -> s
  | Numb(n) -> (string_of_float n)
  | Int(i) -> (string_of_int i)
  | Keyword(k) -> k
  | Datatype(t) -> (match t with 
  					Number -> "float "
  				| 	String -> "string "
  				| 	List -> "struct list* ")
  | Binop(e1,op,e2) -> (match op with
  					Add -> (List.fold_left (fun x y -> x^y) "" (List.map string_of_ccode e1)) ^ " + " ^ (List.fold_left (fun x y -> x^y) "" (List.map string_of_ccode e2))
  				| 	Sub -> (List.fold_left (fun x y -> x^y) "" (List.map string_of_ccode e1)) ^ " - " ^ (List.fold_left (fun x y -> x^y) "" (List.map string_of_ccode e2))
  				| 	Mul -> (List.fold_left (fun x y -> x^y) "" (List.map string_of_ccode e1)) ^ " * " ^ (List.fold_left (fun x y -> x^y) "" (List.map string_of_ccode e2))
  				| 	Div -> (List.fold_left (fun x y -> x^y) "" (List.map string_of_ccode e1)) ^ " / "  ^ (List.fold_left (fun x y -> x^y) "" (List.map string_of_ccode e2))
  				| 	Equal -> (List.fold_left (fun x y -> x^y) "" (List.map string_of_ccode e1)) ^ " == " ^ (List.fold_left (fun x y -> x^y) "" (List.map string_of_ccode e2))
  				| 	Neq -> (List.fold_left (fun x y -> x^y) "" (List.map string_of_ccode e1)) ^ " != " ^ (List.fold_left (fun x y -> x^y) "" (List.map string_of_ccode e2))
  				| 	Less -> (List.fold_left (fun x y -> x^y) "" (List.map string_of_ccode e1)) ^ " < " ^ (List.fold_left (fun x y -> x^y) "" (List.map string_of_ccode e2))
  				| 	Leq -> (List.fold_left (fun x y -> x^y) "" (List.map string_of_ccode e1)) ^ " <= " ^ (List.fold_left (fun x y -> x^y) "" (List.map string_of_ccode e2))
  				| 	Greater -> (List.fold_left (fun x y -> x^y) "" (List.map string_of_ccode e1)) ^ " > " ^ (List.fold_left (fun x y -> x^y) "" (List.map string_of_ccode e2))
  				| 	Geq -> (List.fold_left (fun x y -> x^y) "" (List.map string_of_ccode e1)) ^ " >= "  ^ (List.fold_left (fun x y -> x^y) "" (List.map string_of_ccode e2))
  				| 	Concat -> (List.fold_left (fun x y -> x^y) "" (List.map string_of_ccode e1)) ^ " ^ " ^ (List.fold_left (fun x y -> x^y) "" (List.map string_of_ccode e2))
  			)
  | Assign(id, value) -> (match value with
  					[]  -> id ^ ";"
  				|	[Strg _] -> id ^ " = " ^ (List.fold_left (fun x y -> x^y) "" (List.map string_of_ccode value)) ^ ";"
  				|	[Id _] -> id ^ " = " ^ (List.fold_left (fun x y -> x^y) "" (List.map string_of_ccode value)) ^ ";"
  				|	[Int _] -> id ^ " = " ^ (List.fold_left (fun x y -> x^y) "" (List.map string_of_ccode value)) ^ ";"
  				|	[Numb _] -> id ^ " = " ^ (List.fold_left (fun x y -> x^y) "" (List.map string_of_ccode value)) ^ ";"
  				|	[Keyword _] -> id ^ " = " ^ (List.fold_left (fun x y -> x^y) "" (List.map string_of_ccode value)) ^ ";"
  				|	[Not _] -> id ^ " = " ^ (List.fold_left (fun x y -> x^y) "" (List.map string_of_ccode value)) ^ ";"
  				|	[Neg _] -> id ^ " = " ^ (List.fold_left (fun x y -> x^y) "" (List.map string_of_ccode value)) ^ ";"
  				|	[Call _] -> id ^ " = " ^ (List.fold_left (fun x y -> x^y) "" (List.map string_of_ccode value)) ^ ";"
  				| 	[List (i, e)] -> id ^ " = list_init();\r\n"^ (List.fold_left (fun x y -> x^"list_add("^id^", "^y^");\r\n") "" (List.map string_of_ccode e)) 
  				|   [Binop _] -> id ^ " = " ^ (List.fold_left (fun x y -> x^y) "" (List.map string_of_ccode value)) ^ ";"
  				|   [Mem _] -> id ^ " = " ^ (List.fold_left (fun x y -> x^y) "" (List.map string_of_ccode value)) ^ ";"
  				|   _ -> raise (ParseError "caught parse error")
  				)
  | Not(cl) -> "!(" ^ (List.fold_left (fun x y -> x^y) "" (List.map string_of_ccode cl)) ^ ")"
  | Neg(cl) -> "-(" ^ (List.fold_left (fun x y -> x^y) "" (List.map string_of_ccode cl)) ^ ")"
  | Call(s, cl) -> s ^ "(" ^ (List.fold_left (fun x y -> match x with "" -> y | _ -> x^","^y) "" (List.map string_of_ccode cl)) ^ ");"
  | List(id, cl) -> (List.fold_left (fun x y -> match x with "" -> y | _ -> x^","^y) "" (List.map string_of_ccode cl))
  | Mem(id, i) -> "list_get(" ^ id ^ ", " ^ string_of_int i ^ ")"
  | If(s) -> "if(" ^ (List.fold_left (fun x y -> x^y) "" (List.map string_of_ccode s)) ^ ")"
  | Then(s) -> "{\r\n\t" ^ (List.fold_left (fun x y -> x^y) "" (List.map string_of_ccode s)) ^ "\r\n}"
  | Else(s) -> "else\r\n{\r\n\t" ^ (List.fold_left (fun x y -> x^y) "" (List.map string_of_ccode s)) ^ "\r\n}"
  | Elseif(e, s) -> "elseif(" ^ (List.fold_left (fun x y -> x^y) "" (List.map string_of_ccode e)) ^ ")\r\n{\r\n\t" ^ (List.fold_left (fun x y -> x^y) "" (List.map string_of_ccode s)) ^ "\r\n}"
  | While(e, s) -> "while(" ^(List.fold_left (fun x y -> x^y) "" (List.map string_of_ccode e)) ^ ")" ^
  				   "{\r\n\t" ^ (List.fold_left (fun x y -> x^y) "" (List.map string_of_ccode s)) ^ "\r\n}"
  | Return(s) -> "return " ^ (List.fold_left (fun x y -> x^y) "" (List.map string_of_ccode s)) ^ ";"
  


  (*| Formal(f) -> (List.fold_left (fun x y -> x^y) "" (List.map string_of_ccode f))*)
(*let _ =
  let lexbuf = Lexing.from_channel stdin in
  let program = Parser.program Scanner.token lexbuf in
  (*Translate.translate program*)
  let result = translate program in 
    (List.iter (fun x -> print_endline (string_of_ccode x)) result)*)
  

