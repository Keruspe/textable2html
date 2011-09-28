%{
    #include <stdio.h>
    #include <stdlib.h>

    void yyerror(char * error);
    int yyparse ();
    extern int yylex (void);
    extern int yylex_destroy(void);

    typedef struct html {
        float number;
    } html;
%}

%union { float fval; char cval; struct html * hval; }
%token <cval>  Char
%token <fval>  Number

%type <hval>  Html
%start OUT

%%
OUT : Html { printf("%f\n", $1->number); free($1); }
    ;

Html : Number { html *tmp = (html *) malloc (sizeof(html));  tmp->number = $1; $$ = tmp; }
     ;

%%

void
yyerror(char * error)
{
    fprintf(stderr, "Error : %s\n", error);
    yylex_destroy();
    exit (1);
}

int main() {
    yyparse();
    yylex_destroy();
    return 0;
}



