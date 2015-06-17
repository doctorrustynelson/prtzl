%{ open Ast %}

%token PLUS MINUS TIMES DIVIDE EQ NEQ GREATER LESS GEQ LEQ ASSIGN QUOTE CANCAT DOTOPT NOT COMMA SEMI 
%token LPAREN RPAREN LINSERT RINSERT LDELETE RDELETE LQUERY RQUERY LBRACKET RBRACKET
%token NUMBER STRING VERTEX EDGE LIST IF ELSE ELSEIF ENDIF WHILE DO ENDWHILE RETURN EOF
%token <float> LITERAL
%token <string> ID
%token <string> STR
%token <int> INT

%nonassoc NOELSE /* Precedence and associativity of each operator */ 
%nonassoc ELSE
%right ASSIGN
%left EQ NEQ GREATER LESS GEQ LEQ
%left PLUS MINUS
%left TIMES DIVIDE CANCAT
%nonassoc UMINUS NOT

%start fdecl
%type < Ast.fdecl> fdecl

%%

fdecl:
  NUMBER ID LPAREN arguement_list RPAREN vdecl_list stmt_list
  	{ { 
  		fname   = $2;
    	formals = List.rev $4;
    	locals  = List.rev $6;
    	body    = List.rev $7 } }
| STRING ID LPAREN arguement_list RPAREN vdecl_list stmt_list 
  	{ { 
  		fname   = $2;
    	formals = List.rev $4;
    	locals  = List.rev $6;
    	body    = List.rev $7 } }
| VERTEX ID LPAREN arguement_list RPAREN vdecl_list stmt_list 
  	{ { 
  		fname   = $2;
    	formals = List.rev $4;
    	locals  = List.rev $6;
    	body    = List.rev $7 } }
| EDGE ID LPAREN arguement_list RPAREN vdecl_list stmt_list 
  	{ { 
  		fname   = $2;
    	formals = List.rev $4;
    	locals  = List.rev $6;
    	body    = List.rev $7 } }

vdecl_list:
  /*nothing*/	{ [] }
| vdecl_list vdecl { $2 :: $1 }

vdecl:
  NUMBER ID 		{ $2 }
| STRING ID 		{ $2 }
| VERTEX ID 		{ $2 }
| EDGE ID 			{ $2 }

arguement_list:
                { [] } 
| NUMBER ID 		{ [$2] }
| STRING ID 		{ [$2] }
| VERTEX ID 		{ [$2] }
| EDGE ID 			{ [$2] }
| arguement_list COMMA ID 	{ $3 :: $1 }

stmt_list:
/* nothing */		{ [] }
| stmt_list stmt 	{ $2 :: $1 }

/*elseif_list:										3 rules never reduced
  nothing			{ [] }	
| elseif_list elseif	{ $2 :: $1 }

elseif:
  ELSEIF LPAREN expr RPAREN stmt 		{ Elseif($3, $5) }*/

stmt:
  expr SEMI				{ Expr($1) }
| IF LPAREN expr RPAREN stmt %prec NOELSE ENDIF	{ If($3, $5, [Block([])], Block([]) ) }
| IF LPAREN expr RPAREN stmt ELSE stmt ENDIF 	{ If($3, $5, [Block([])], $7) }
| WHILE LPAREN expr RPAREN DO stmt ENDWHILE		{ While($3, $6) }
| RETURN expr SEMI	{ Return($2) }


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
/*| MINUS expr %prec UMINUS { Neg($2) }*/  /*shift reduce conflict */
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
/*| ID LBRACKET INT RBRACKET { Mem($1, $3) }*/  /*shift reduce conflict*/
/*| LBRACKET RBRACKET { [] }*/
| LBRACKET list RBRACKET { List(List.rev $2) }
| LPAREN expr RPAREN { $2 }
| ID LPAREN list RPAREN { Call($1, List.rev $3) }  /*shift reduce conflict*/
/*| INT 				{ Int($1) } */
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


