{ open Parser }

rule token = parse
  [' ' '\t' '\r' '\n'] { token lexbuf }
| '+' { PLUS }					| '>' { GREATER }
| '-' { MINUS }					| '<' { LESS }
| '*' { TIMES }					| "==" { EQ }
| '/' { DIVIDE }				| "!=" { NEQ }
| '=' { ASSIGN }				| ">=" { GEQ }
| '"' { QUOTE }					| "<=" { LEQ }
| '!' { NOT } 					| ','  { COMMA }
| '^' { CONCAT }				| '.' { DOTOPT }
| '(' { LPAREN }				| ')' { RPAREN }
| '[' { LBRACKET }				| ']' { RBRACKET }
(*| '{' { LBRACE }				| '}' { RBRACE }*)
| "<+" { LINSERT }				| "+>" { RINSERT }
| "<-" { LDELETE }				| "->" { RDELETE }	
| "<?" { LQUERY }				| "?>" { RQUERY }
| "Number" { NUMBER }			| "String" { STRING }
| "Vertex" { VERTEX }			| "Edge" { EDGE }
| "if" { IF }					| "else" { ELSE }
| "elseif" { ELSEIF }			| "endif" { ENDIF }
| "while" { WHILE }				| "do" { DO }	
| "endwhile" { ENDWHILE }		| "return" { RETURN }
| "endfunc" { ENDFUNC }			| ';' { SEMI }
(*| "in" { IN }					| "out" { OUT }
| "in_degree" { INDEGREE }		| "out_degree" { OUTDEGREE }
| "to" { TO }					| "from" { FROM }
| "weight" { WEIGHT }*)
| "endelseif" { ENDELSEIF }		| "List" { LIST }
| "/*" { comment lexbuf }
| ['0'-'9']+ as lit { INT(int_of_string lit) } 
| ['0'-'9']+('.'['0'-'9']+)? as num { LITERAL(float_of_string num) }
| '"'[^'\n' '"']+'"' as str { STR(str) }
| ['a'-'z' 'A'-'Z']['a'-'z' 'A'-'Z' '0'-'9' '_']* as lit { ID(lit) } 
| _ as char { raise (Failure("illegal character " ^ Char.escaped char)) }
| eof { EOF }

and comment = parse
"*/" { token lexbuf } (* End-of-comment *)
| _ { comment lexbuf } (* Eat everything else *)
