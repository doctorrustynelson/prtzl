%{ open PRTZL_ast %}

%token PLUS MINUS TIMES DIVIDE EQ NEQ GREATER LESS GEQ LEQ ASSIGN QUOTE CANCAT DOTOPT NOT COMMA
%token LPAREN RPAREN LINSERT RINSERT LDELETE RDELETE LQUERY RQUERY LBRACKET RBRACKET LBRACE RBRACE
%token NUMBER STRING VERTEX EDGE LIST IF ELSE ELSEIF ENDIF WHILE DO ENDWHILE EOF
%token <float> LITERAL
%token <string> ID
%token <string> STR
%token <int> INT

%nonassoc NOELSE /* Precedence and associativity of each operator */ 
%nonassoc ELSE
%right ASSIGN
%left EQ NEQ GREATER LESS GEQ LEQ
%left PLUS MINUS
%left TIMES DIVIDE
%nonassoc UMINUS NOT

%start stmt
%type < PRTZL_ast.stmt> stmt

%%

stmt_list:
/* nothing */		{ [] }
| stmt_list stmt 	{ $2 :: $1 }

elseif_list:
  /*nothing*/			{ [] }	
| elseif_list elseif	{ $2 :: $1 }

elseif:
  ELSEIF LPAREN expr RPAREN stmt 		{ Elseif($3, $5) }

stmt:
  expr				{ Expr($1) }
| LBRACE stmt_list RBRACE 	{ Block(List.rev $2) }
| IF LPAREN expr RPAREN stmt %prec NOELSE ENDIF	{ If($3, $5, [Block([])], Block([]) ) }
| IF LPAREN expr RPAREN stmt ELSE stmt ENDIF 	{ If($3, $5, [Block([])], $7) }
| WHILE LPAREN expr RPAREN stmt ENDWHILE 		{ While($3, $5) }


expr:
  expr PLUS   expr 	{ Binop($1, Add, $3) }
| expr MINUS  expr 	{ Binop($1, Sub, $3) }
| expr TIMES  expr 	{ Binop($1, Mul, $3) }
| expr DIVIDE expr 	{ Binop($1, Div, $3) }
| expr EQ	  expr 	{ Binop($1, Equal, $3) }
| expr NEQ    expr 	{ Binop($1, Neq, $3) }
| expr LESS   expr 	{ Binop($1, Less, $3) }
| expr LEQ    expr 	{ Binop($1, Leq, $3) }
| expr GREATER expr { Binop($1, Greater, $3) }
| expr GEQ	  expr 	{ Binop($1, Geq, $3) }
| MINUS expr %prec UMINUS { Neg($2) }
| NOT expr			{ Not($2) }
| expr CANCAT expr 	{ Binop($1, Cancat, $3) }
| LINSERT expr RINSERT { Insert($2) }
| LDELETE expr RDELETE { Delete($2) }
| LQUERY expr  RQUERY  { Query($2) }
/*| QUOTE STR QUOTE  { Str($2) }*/
| STR 			   	{ Str($1) }
| ID ASSIGN expr   	{ Assign($1, $3) }
| NUMBER ID ASSIGN expr { Assign($2, $4) }
| STRING ID ASSIGN expr { Assign($2, $4) }
| VERTEX ID ASSIGN expr { Assign($2, $4) }
| LIST ID ASSIGN expr { Assign($2, $4) }
| ID LBRACKET INT RBRACKET { Mem($1, $3) }
/*| LIST ID ASSIGN expr 	{ List($4) }*/
/*| LBRACKET RBRACKET { [] }*/
| LBRACKET list RBRACKET { List(List.rev $2) }
| LPAREN expr RPAREN { $2 }
| ID LPAREN list RPAREN { Call($1, $3) }
| INT 				{ Int($1) } 
| LITERAL		   	{ Num($1) }
| NUMBER ID 	   	{ Id($2) }					/*Number my_num*/
| STRING ID	  	   	{ Id($2) }					/*String my_string*/
| VERTEX ID 		{ Id($2) }
| EDGE ID 			{ Id($2) }
| LIST ID 			{ Id($2) }
| ID 			   	{ Id($1) }
/*| STR 			   { Str($1) }*/

list:
	/*nothing*/		{ [] }
|	ID 				{ [Id($1)] }
|	LITERAL			{ [Num($1)] }
|	STR 			{ [Str($1)] }
| 	list COMMA expr { $3 :: $1 }

