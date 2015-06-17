type operator = Add | Sub | Mul | Div | Equal | Neq | Less | Leq 
			  | Greater | Geq | Cancat

(*type datatype = Number | String | Vertex | Edge | Void*)


type expr =
       Num of float
     | Str of string
     | Id of string
     | Int of int
     | Assign of string * expr
     | Binop of expr * operator * expr
     | Not of expr
     | Neg of expr
     | Insert of expr
     | Delete of expr
     | Query of expr
     | List of expr list
     | Mem of string * int 
     | Call of string * expr list


type stmt = 
	   Block of stmt list
	 | Expr of expr
	 | If of expr * stmt * stmt list * stmt
	 | Elseif of expr * stmt
	 | While of expr * stmt
	 | Return of expr


type fdecl = {
		fname : string; (* Name of the function *) 
		formals : string list; (* Formal argument names *) 
		locals : string list; (* Locally defined variables *) 
		body : stmt list;
}
