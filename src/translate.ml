open Ast
open Ccode

module StringMap = Map.Make(String)

exception ParseError of string

let rec expr = function
			Str i -> [Strg i]
	      | Id s -> [Id s]
	      | Int i -> [Int i]
	      | Num n -> [Numb n]
	      | Binop (e1, op, e2) -> [Binop ((expr e1), op, (expr e2))]
	      | Assign (id, value) -> [Assign (id, (expr value))]
	      | Keyword k -> [Keyword k]
	      | Not(n) -> [Not (expr n)]
	      | Neg(n) -> [Neg (expr n)]
	      | Call(s, el) -> [Call (s, (List.concat (List.map expr el)))]
	      | List(el) -> [List ("", (List.concat (List.map expr el)))]
	      | Noexpr -> []

let rec stmt = function
			Block sl     -> List.concat (List.map stmt sl)
	      | Expr e       -> expr e @ [Keyword ";"]
	      | If (e1, e2, e3, e4) -> (match e3 with
	      					[] -> (match e4 with 
			      					Block([]) -> [If (expr e1)] @ [Then (stmt e2)]
			      				|   _ -> [If (expr e1)] @ [Then (stmt e2)] @ [Else (stmt e4)]	
			      			)
	      				| 	(Elseif(e,s)) ::tail -> [If (expr e1)] @ [Then (stmt e2)] @ [Elseif (expr e, stmt s)] @ List.concat (List.map stmt tail) @ [Else (stmt e4)]
	      				|   _ -> raise (ParseError "caught parse error")
	      				)(*[Keyword "if "] @ expr e1 @ stmt e2 @  List.concat (List.map stmt e3) @ stmt e4*)
	      | Elseif(e, s) -> [Elseif ((expr e), (stmt s))]
	      | While(e, s) -> [While ((expr e), (stmt s))]
	      | Return e     -> [Return (expr e) ]

let translate (globals, statements, functions) =

	let translatefunc fdecl =
	    [Datatype fdecl.rtype] @ [Id fdecl.fname] @ 
	    [Keyword "("] @ [Keyword ")\r\n{\r\n"] @
	    stmt (Block fdecl.body) @ [Keyword "\r\n}\r\n"](*@  (* Body *)
	    [Ret 0]   (* Default = return 0 *)*)
	and translatestm stm = 
		stmt (Block stm)

	and translatestg glob =
		[Datatype glob.vtype] @ expr glob.value

	in List.concat (List.map translatefunc functions ) @
	   [Main] @ List.concat (List.map translatestg globals) @ translatestm statements @ [Endmain]

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
  				|   _ -> raise (ParseError "caught parse error")
  				)
  | Not(cl) -> "!(" ^ (List.fold_left (fun x y -> x^y) "" (List.map string_of_ccode cl)) ^ ")"
  | Neg(cl) -> "-(" ^ (List.fold_left (fun x y -> x^y) "" (List.map string_of_ccode cl)) ^ ")"
  | Call(s, cl) -> s ^ "(" ^ (List.fold_left (fun x y -> match x with "" -> y | _ -> x^","^y) "" (List.map string_of_ccode cl)) ^ ");"
  | List(id, cl) -> (List.fold_left (fun x y -> match x with "" -> y | _ -> x^","^y) "" (List.map string_of_ccode cl))
  | If(s) -> "if(" ^ (List.fold_left (fun x y -> x^y) "" (List.map string_of_ccode s)) ^ ")"
  | Then(s) -> "{\r\n\t" ^ (List.fold_left (fun x y -> x^y) "" (List.map string_of_ccode s)) ^ "\r\n}"
  | Else(s) -> "else\r\n{\r\n\t" ^ (List.fold_left (fun x y -> x^y) "" (List.map string_of_ccode s)) ^ "\r\n}"
  | Elseif(e, s) -> "elseif(" ^ (List.fold_left (fun x y -> x^y) "" (List.map string_of_ccode e)) ^ ")\r\n{\r\n\t" ^ (List.fold_left (fun x y -> x^y) "" (List.map string_of_ccode s)) ^ "\r\n}"
  | While(e, s) -> "while(" ^(List.fold_left (fun x y -> x^y) "" (List.map string_of_ccode e)) ^ ")" ^
  				   "{\r\n\t" ^ (List.fold_left (fun x y -> x^y) "" (List.map string_of_ccode s)) ^ "\r\n}"
  | Return(s) -> "return " ^ (List.fold_left (fun x y -> x^y) "" (List.map string_of_ccode s)) ^ ";"

(*let _ =
  let lexbuf = Lexing.from_channel stdin in
  let program = Parser.program Scanner.token lexbuf in
  (*Translate.translate program*)
  let result = translate program in 
    (List.iter (fun x -> print_endline (string_of_ccode x)) result)*)
  

