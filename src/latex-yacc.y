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
%token Begin End Open Close Tabular TableTok NewLine NewCell HLine CLine MultiColumn Caption

%type <line> Lines
%type <cell> Line
%type <table> Table
%type <dummy> Garbage BeginTabular EndTabular BeginTable EndTable Horizontal

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

Table : BeginTabular Format Close Lines EndTabular { $$ = new_table ($2, $4, NULL); }
      | BeginTable BeginTabular Format Close Lines EndTabular EndTable { $$ = new_table ($3, $5, NULL); }
      | BeginTable BeginTabular Format Close Lines EndTabular Caption Open String Close EndTable { $$ = new_table ($3, $5, $9); }
      | BeginTable Caption Open String Close BeginTabular Format Close Lines EndTabular EndTable { $$ = new_table ($7, $9, $4); }
      ;

BeginTabular : Begin Open Tabular Close Open { $$ = NULL; }
           ;

EndTabular : End Open Tabular Close { $$ = NULL; }
         ;

BeginTable : Begin Open TableTok Close { $$ = NULL; }
           ;

EndTable : End Open TableTok Close { $$ = NULL; }
         ;

Lines : Line { $$ = new_line ($1, NULL); }
      | Line NewLine { $$ = new_line ($1, NULL); }
      | Line NewLine Lines { $$ = new_line ($1, $3); }
      | Horizontal { $$ = NULL; }
      | Horizontal NewLine { $$ = NULL; }
      | Horizontal Lines { $$ = $2; }
      | Horizontal NewLine Lines { $$ = $3; }
      ;

Horizontal : HLine { $$ = NULL; }
           | CLine Open String Close { $$ = NULL; }
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
        | Begin { $$ = NULL; }
        | End { $$ = NULL; }
        | Open { $$ = NULL; }
        | Close { $$ = NULL; }
        | TableTok { $$ = NULL; }
        | Tabular { $$ = NULL; }
        | HLine { $$ = NULL; }
        | CLine { $$ = NULL; }
        | Garbage String { $$ = NULL; }
        | Garbage Number { $$ = NULL; }
        | Garbage NewLine { $$ = NULL; }
        | Garbage NewCell { $$ = NULL; }
        | Garbage Begin { $$ = NULL; }
        | Garbage End { $$ = NULL; }
        /* The two following rules cause shift/reduce warnings... */
        | Garbage Open { $$ = NULL; }
        | Garbage Close { $$ = NULL; }
        | Garbage TableTok { $$ = NULL; }
        | Garbage Tabular { $$ = NULL; }
        | Garbage HLine { $$ = NULL; }
        | Garbage CLine { $$ = NULL; }
        ;
%%

