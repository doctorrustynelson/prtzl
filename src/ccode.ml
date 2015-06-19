type cstmt =
	Strg of string
|	Numb of float
|	Int	 of int
|	Id 	 of string
| 	Keyword of string
|   Main	
| 	Endmain 
| 	Datatype of Ast.datatype

type prog = {
	text : cstmt array;
}