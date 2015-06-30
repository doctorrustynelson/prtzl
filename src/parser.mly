%{ open Ast %}

%token PLUS MINUS TIMES DIVIDE EQ NEQ GREATER LESS GEQ LEQ ASSIGN QUOTE CONCAT DOTOPT NOT COMMA SEMI 
%token LPAREN RPAREN LINSERT RINSERT LDELETE RDELETE LQUERY RQUERY LBRACKET RBRACKET
%token NUMBER STRING VERTEX EDGE LIST IF ELSE ELSEIF ENDIF ENDELSEIF WHILE DO ENDWHILE ENDFUNC RETURN EOF
%token <float> LITERAL
%token <string> ID
%token <string> STR
%token <int> INT

%nonassoc NOELSE /* Precedence and associativity of each operator */ 
%nonassoc ELSE
%right ASSIGN
%left EQ NEQ GREATER LESS GEQ LEQ
%left PLUS MINUS
%left TIMES DIVIDE CONCAT
%nonassoc UMINUS NOT

%start program
%type < Ast.program> program

%%

program:
  /* nothing */   { [], [], [] }
| program vdecl { let (a,b,c) = $1 in ($2 :: a), b, c }
| program stmt { let (a,b,c) = $1 in a, ($2 :: b), c }
| program fdecl { let (a,b,c) = $1 in a, b, ($2 :: c) }


fdecl:
  NUMBER ID LPAREN arguement_list RPAREN vdecl_list stmt_list ENDFUNC
  	{ {
      rtype   = Number; 
  		fname   = $2;
    	formals = List.rev $4;
    	locals  = List.rev $6;
    	body    = List.rev $7 } }
| STRING ID LPAREN arguement_list RPAREN vdecl_list stmt_list ENDFUNC
  	{ { 
      rtype   = String;
  		fname   = $2;
    	formals = List.rev $4;
    	locals  = List.rev $6;
    	body    = List.rev $7 } }
| VERTEX ID LPAREN arguement_list RPAREN vdecl_list stmt_list ENDFUNC
  	{ { 
      rtype   = Vertex;
  		fname   = $2;
    	formals = List.rev $4;
    	locals  = List.rev $6;
    	body    = List.rev $7 } }
| EDGE ID LPAREN arguement_list RPAREN vdecl_list stmt_list ENDFUNC
  	{ { 
      rtype   = Edge;
  		fname   = $2;
    	formals = List.rev $4;
    	locals  = List.rev $6;
    	body    = List.rev $7 } }

vdecl_list:
  /*nothing*/	{ [] }
| vdecl_list vdecl { $2 :: $1 }  /*shift reduce conflcit*/

vdecl:
  NUMBER ID SEMI    { {vtype=Number; vname=$2; value=Assign($2, Num(0.))} }
| STRING ID SEMI    { {vtype=String; vname=$2; value=Assign($2, Str("\"\"") )} }
| VERTEX ID SEMI    { {vtype=Vertex; vname=$2; value=Assign($2, Vertex("") )} }
| EDGE ID   SEMI    { {vtype=  Edge; vname=$2; value=Assign($2, Edge("") )} }
| LIST ID   SEMI    { {vtype=  List; vname=$2; value=Assign($2, List([]))} }
| NUMBER ID ASSIGN expr SEMI { {vtype=Number; vname=$2; value=Assign($2, $4)} }
| STRING ID ASSIGN expr SEMI { {vtype=String; vname=$2; value=Assign($2, $4)} }
| VERTEX ID ASSIGN expr SEMI { {vtype=Vertex; vname=$2; value=Assign($2, $4)} }
| EDGE   ID ASSIGN expr SEMI { {vtype=  Edge; vname=$2; value=Assign($2, $4)} }
| LIST   ID ASSIGN expr SEMI { {vtype=  List; vname=$2; value=Assign($2, $4)} }

arguement_list:
                { [] } 
| arguement     { [$1] }
| arguement_list COMMA arguement 	 { $3 :: $1 }

arguement:
  NUMBER ID     { {ftype = Number; frname = $2} }
| STRING ID     { {ftype = String; frname = $2} }
| VERTEX ID     { {ftype = Vertex; frname = $2} }
| EDGE ID       { {ftype = Edge; frname = $2} }
| LIST ID       { {ftype = List; frname = $2} }

stmt_list:
/* nothing */		{ [] }
| stmt_list stmt 	{ $2 :: $1 }

elseif_list:										/* rules never reduced*/
  /*nothing*/			{ [] }	
| elseif_list elseif	{ $2 :: $1 }

elseif:
  ELSEIF LPAREN expr RPAREN stmt_list	{ Elseif($3, List.rev $5) }

stmt:
  expr SEMI			{ Expr($1) }
| IF LPAREN expr RPAREN stmt_list %prec NOELSE ENDIF	{ If($3, List.rev $5, [Block([])], [Block([])] ) }
| IF LPAREN expr RPAREN stmt_list ELSE stmt_list ENDIF 	{ If($3, List.rev $5, [Block([])], List.rev $7) }
| IF LPAREN expr RPAREN stmt_list elseif_list ENDELSEIF ELSE stmt_list ENDIF  { If($3, List.rev $5, List.rev $6, List.rev $9) }
| WHILE LPAREN expr RPAREN DO stmt_list ENDWHILE		{ While($3, List.rev $6) }
| RETURN expr SEMI	{ Return($2) }


expr:
  expr PLUS   expr 	{ Binop($1, Add, $3) }
| expr MINUS  expr 	{ Binop($1, Sub, $3) }
| expr TIMES  expr 	{ Binop($1, Mul, $3) }
| expr DIVIDE expr 	{ Binop($1, Div, $3) }
| expr EQ	    expr 	{ Binop($1, Equal, $3) }
| expr NEQ    expr 	{ Binop($1, Neq, $3) }
| expr LESS   expr 	{ Binop($1, Less, $3) }
| expr LEQ    expr 	{ Binop($1, Leq, $3) }
| expr GREATER expr { Binop($1, Greater, $3) }
| expr GEQ	  expr 	{ Binop($1, Geq, $3) }
| expr CONCAT expr 	{ Binop($1, Concat, $3) }
| MINUS expr %prec UMINUS { Neg($2) }  
| NOT expr      { Not($2) }
| LINSERT expr RINSERT { Insert($2) }
| LDELETE expr RDELETE { Delete($2) }
| LQUERY expr  RQUERY  { Query($2) }
| ID ASSIGN expr   	{ Assign($1, $3) }
| ID LBRACKET expr RBRACKET ASSIGN expr    { ListAssign($1, $3, $6) }
| ID LBRACKET expr RBRACKET { Mem($1, $3) }
| LBRACKET list RBRACKET { List(List.rev $2) }
| LPAREN expr RPAREN { AddParen($2) }
| ID LPAREN list RPAREN { Call($1, List.rev $3) } 
| ID DOTOPT ID    { Property($1, $3) }
| ID DOTOPT ID ASSIGN expr   { PropertyAssign($1, $3, $5) }
| INT 				  { Int($1) } 
| LITERAL		   	{ Num($1) }
| STR           { Str($1) }
| ID 			   	  { Id($1) }


list:
	/*nothing*/		{ [] }
|	ID 				{ [Id($1)] }
|	LITERAL		{ [Num($1)] }
|	STR 			{ [Str($1)] }
| INT       { [Int($1)] }
| list COMMA expr { $3 :: $1 }


