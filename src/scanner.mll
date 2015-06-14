{ open Parser }

rule token = parse 
	  [' ' '\t' '\r' '\n'] { token lexbuf }
	| '+' { PLUS }
	| '-' { MINUS }
	| '*' { TIMES }
	| '/' { DIVIDE }
	| ',' { SEQUENCE }
	| '=' { ASSIGNMENT }
	| ['0'-'9']+ as lit { LITERAL( int_of_string lit ) }
	| '$'['0'-'9'] as lit { VARIABLE(int_of_char lit.[1] - 48) }
	| eof { EOF }