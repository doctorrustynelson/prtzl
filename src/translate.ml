open Ast

module StringMap = Map.Make(String)

let rec expr = function
			Str i -> [Str i]
	      | Id s -> [Id s]
	      | Int i -> [Int i]
	      | Keyword k -> [Keyword k]

let rec stmt = function
			Block sl     -> List.concat (List.map stmt sl)
	      | Expr e       -> expr e 
	      | Return e     -> [Keyword "return "] @ expr e

let translate (statements, functions) =

	let translatefunc fdecl =
	    (*stmt (Block stm) @ *)
	    stmt (Block fdecl.body) (*@  (* Body *)
	    [Ret 0]   (* Default = return 0 *)*)
	and translatestm stm = 
		stmt (Block stm)

	in List.concat (List.map translatefunc functions ) @
	   translatestm statements 

let rec string_of_expr = function
    Str(l) -> l ^ ";"
  | Id(s) -> s ^ ";"
  | Num(n) -> (string_of_float n) ^ ";"
  | Int(i) -> (string_of_int i) ^ ";"
  | Keyword(k) -> k

let rec string_of_stmt = function
    Block(stmts) ->
      "{\n" ^ String.concat "" (List.map string_of_stmt stmts) ^ "}\n"
  | Expr(expr) -> string_of_expr expr ^ ";\n"
  | Return(expr) -> "return " ^ string_of_expr expr ^ ";\n"

let string_of_vdecl id = "int " ^ id ^ ";\n"

let string_of_fdecl fdecl =
  fdecl.fname ^ "(" ^ String.concat ", " fdecl.formals ^ ")\n{\n" ^
  String.concat "" (List.map string_of_vdecl fdecl.locals) ^
  String.concat "" (List.map string_of_stmt fdecl.body) ^
  "}\n"
  


let _ =
    let lexbuf = Lexing.from_channel stdin in
    let program = Parser.program Scanner.token lexbuf in
    let result = translate program in 
    (List.iter (fun x -> print_endline (string_of_expr x)) result)