type cstmt =
	Strg of string
|	Numb of float
|	Int	 of int
|	Id 	 of string
|   Vertex of string
| 	Edge of string 
| 	Keyword of string
|   Main	
| 	Endmain 
| 	Datatype of Ast.datatype
| 	Binop	of (string * cstmt list) * Ast.operator * (string * cstmt list)
|   Assign of string * (string * cstmt list)
| 	Not of cstmt list
| 	Neg of cstmt list
|  	Call of string * cstmt list 
|   List of string * cstmt list
|   Mem of string * cstmt list
| 	ListAssign of string * cstmt list * cstmt list
|  	If of cstmt list
|  	Then of cstmt list
| 	Else of cstmt list
|   Elseif of cstmt list * cstmt list 
|   While of cstmt list * cstmt list 
|   Return of cstmt list
| 	Insert of cstmt list
|   Query of cstmt list 
| 	Delete of cstmt list
| 	Property of string * string
| 	PropertyAssign of string * string * cstmt list
| 	AddParen of cstmt list

type prog = {
	text : cstmt array;
}