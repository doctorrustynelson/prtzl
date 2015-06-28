type cstmt =
	Strg of string
|	Numb of float
|	Int	 of int
|	Id 	 of string
| 	Keyword of string
|   Main	
| 	Endmain 
| 	Datatype of Ast.datatype
| 	Binop	of Ast.operator
|   Assign of string * cstmt list
| 	Not of cstmt list
| 	Neg of cstmt list
|  	Call of string * cstmt list 
|   List of string * cstmt list
|  	If of cstmt list
|  	Then of cstmt list
| 	Else of cstmt list
|   While of cstmt list * cstmt list 
|   Insert of string
|   Query of string
|   Delete of string

type prog = {
	text : cstmt array;
}