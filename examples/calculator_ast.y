%token NUMBER
%left '+' '-'
%left '*' '/'

%%

expression: NUMBER { $$ = [:number, $1] }
          | expression '+' expression { $$ = [:binary, :+, $1, $3] }
          | expression '-' expression { $$ = [:binary, :-, $1, $3] }
          | expression '*' expression { $$ = [:binary, :*, $1, $3] }
          | expression '/' expression { $$ = [:binary, :/, $1, $3] }
          | '(' expression ')' { $$ = $2 }
          ;
