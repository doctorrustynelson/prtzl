open Ast
open Ccode

module StringMap = Map.Make(String)

let rec expr = function
			Str i -> [Strg i]
	      | Id s -> [Id s]
	      | Int i -> [Int i]
	      | Num n -> [Numb n]
	      (*| Binop (e1, op, e2) -> [op] @ expr e1 @ expr e2*)
	      | Keyword k -> [Keyword k]

let rec stmt = function
			Block sl     -> List.concat (List.map stmt sl)
	      | Expr e       -> expr e 
	      | Return e     -> [Keyword "return "] @ expr e

let translate (statements, functions) =

	let translatefunc fdecl =
	    [Datatype fdecl.rtype] @ [Id fdecl.fname] @ 
	    [Keyword "("] @ [Keyword ")\r\n{\r\n"] @
	    stmt (Block fdecl.body) @ [Keyword "\r\n}\r\n"](*@  (* Body *)
	    [Ret 0]   (* Default = return 0 *)*)
	and translatestm stm = 
		stmt (Block stm)

	in List.concat (List.map translatefunc functions ) @
	   [Main] @ translatestm statements @ [Endmain]

let rec string_of_ccode = function
	Main -> "int main() { \r\n"
  | Endmain -> "\t return 0; \r\n}\r\n"	
  | Strg(l) -> l ^ ";"
  | Id(s) -> s
  | Numb(n) -> (string_of_float n) ^ ";"
  | Int(i) -> (string_of_int i) ^ ";"
  | Keyword(k) -> k
  | Datatype(t) -> match t with 
  					Number -> "float "
  				| 	String -> "string " 

(*let _ =
  let lexbuf = Lexing.from_channel stdin in
  let program = Parser.program Scanner.token lexbuf in
  (*Translate.translate program*)
  let result = translate program in 
    (List.iter (fun x -> print_endline (string_of_ccode x)) result)*)
  

