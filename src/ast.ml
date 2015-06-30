type operator = Add | Sub | Mul | Div | Equal | Neq | Less | Leq 
			  | Greater | Geq | Concat

type datatype = Number | String | Vertex | Edge | Void | List


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
     | Mem of string * expr 
     | ListAssign of string * expr * expr
     | Call of string * expr list
     | Keyword of string
     | Vertex of string
     | Edge of string
     | Property of string * string 
     | PropertyAssign of string * string * expr
     | AddParen of expr
     | Noexpr



type stmt = 
	   Block of stmt list
	 | Expr of expr
	 | If of expr * stmt list * stmt list * stmt list
	 | Elseif of expr * stmt list
	 | While of expr * stmt list
	 | Return of expr



type vdecl = {
          vtype : datatype;
          vname : string;
          value : expr;
}

type formal = {
          ftype : datatype;
          frname : string;
}

type func_decl = {
          rtype : datatype;
		fname : string; (* Name of the function *) 
		formals : formal list; (* Formal argument names *) 
		locals : vdecl list; (* Locally defined variables *) 
		body : stmt list;
}

type program = vdecl list * stmt list * func_decl list