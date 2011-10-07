#include <stdio.h>
#include <stdlib.h>

extern FILE * yyin;
const char *input_file;

extern int yylex_destroy ();
extern int yyparse ();

void
yyerror(char *error)
{
    fprintf (stderr, "Error : %s\n", error);
    yylex_destroy ();
    exit (1);
}

int
main(int argc, char *argv[])
{
    if (argc != 2) {
        fprintf (stderr, "usage: %s <file>\n", argv[0]);
        yyerror ("bad invocation");
    }
    input_file = argv[1];
    yyin = fopen (input_file, "r");
    yyparse ();
    yylex_destroy ();
    fclose (yyin);
    return 0;
}

