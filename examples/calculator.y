%token NUMBER
%left '+' '-'
%left '*' '/'

%%

expression: NUMBER
          | expression '+' expression { $$ = $1 + $3 }
          | expression '-' expression { $$ = $1 - $3 }
          | expression '*' expression { $$ = $1 * $3 }
          | expression '/' expression { $$ = $1 / $3 }
          | '(' expression ')' { $$ = $2 }
          ;
