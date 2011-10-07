%{
    #include "latextohtml.h"

    extern int yylex ();
    extern void yyerror (char *error);

    extern const char *input_file;
    extern bool numbers_only;
%}

%union {
    float number;
    char character;
    char *string;
    struct Line *line;
    struct Cell *cell;
    struct Table *table;
    void *dummy;
}

%token <number> Number
%token <string> String Format
%token BeginTab Open Close EndTab NewLine NewCell HLine MultiColumn

%type <line> Lines
%type <cell> Line
%type <table> Table
%type <dummy> Garbage

%start OUT

%expect 2 /* See in Garbage */

%%
OUT : Garbage Table {
            htmlize ($2);
            free_table ($2);
            exit (0);
      }
    | Table Garbage {
            htmlize ($1);
            free_table ($1);
            exit (0);
      }
    | Garbage Table Garbage {
            htmlize ($2);
            free_table ($2);
            exit (0);
      }
    | Table {
            htmlize ($1);
            free_table ($1);
            exit (0);
      }
    ;

Table : BeginTab Open Format Close Lines EndTab { $$ = new_table ($3, $5); }
      ;

Lines : Line { $$ = new_line ($1, NULL); }
      | Line NewLine { $$ = new_line ($1, NULL); }
      | Line NewLine Lines { $$ = new_line ($1, $3); }
      | HLine { $$ = NULL; }
      | HLine NewLine { $$ = NULL; }
      | HLine Lines { $$ = $2; }
      | HLine NewLine Lines { $$ = $3; }
      ;

Line : String {
           CellContent cc = { .string = $1 };
           $$ = new_cell (STRING, cc, 1, '\0', NULL);
       }
     | String NewCell Line {
           CellContent cc = { .string = $1 };
           $$ = new_cell (STRING, cc, 1, '\0', $3);
       }
     | Number {
           CellContent cc = { .number = $1 };
           $$ = new_cell (NUMBER, cc, 1, '\0', NULL);
       }
     | Number NewCell Line {
           CellContent cc = { .number = $1 };
           $$ = new_cell (NUMBER, cc, 1, '\0', $3);
       }
     | MultiColumn Open Number Close Open Format Close Open String Close {
           CellContent cc = { .string = $9 };
           $$ = new_cell (STRING, cc, $3, $6[0], NULL);
       }
     | MultiColumn Open Number Close Open Format Close Open String Close NewCell Line {
           CellContent cc = { .string = $9 };
           $$ = new_cell (STRING, cc, $3, $6[0], $12);
       }
     | MultiColumn Open Number Close Open Format Close Open Number Close {
           CellContent cc = { .number = $9 };
           $$ = new_cell (NUMBER, cc, $3, $6[0], NULL);
       }
     | MultiColumn Open Number Close Open Format Close Open Number Close NewCell Line {
           CellContent cc = { .number = $9 };
           $$ = new_cell (NUMBER, cc, $3, $6[0], $12);
       }
     | NewCell {
           CellContent cc = { .string = strdup ("") /* Since we always free it */ };
           $$ = new_cell (STRING, cc, 1, '\0', NULL);
       }
     | NewCell Line {
           CellContent cc = { .string = strdup ("") /* Since we always free it */ };
           $$ = new_cell (STRING, cc, 1, '\0', $2);
       }
     ;

Garbage : String { $$ = NULL; }
        | Number { $$ = NULL; }
        | NewLine { $$ = NULL; }
        | NewCell { $$ = NULL; }
        | BeginTab { $$ = NULL; }
        | Open { $$ = NULL; }
        | Close { $$ = NULL; }
        | EndTab { $$ = NULL; }
        | HLine { $$ = NULL; }
        | Garbage String { $$ = NULL; }
        | Garbage Number { $$ = NULL; }
        | Garbage NewLine { $$ = NULL; }
        | Garbage NewCell { $$ = NULL; }
        | Garbage BeginTab { $$ = NULL; }
        /* The two following rules cause shift/reduce warnings... */
        | Garbage Open { $$ = NULL; }
        | Garbage Close { $$ = NULL; }
        | Garbage EndTab { $$ = NULL; }
        | Garbage HLine { $$ = NULL; }
        ;
%%

