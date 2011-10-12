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
%token Begin End Open Close Tabular TableTok NewLine NewCell HLine CLine MultiColumn Caption LatexDirective
%token Alpha ALPHA Beta BETA Gamma GAMMA Delta DELTA

%type <line> Lines
%type <cell> Line
%type <table> Table
%type <string> Text
%type <dummy> Garbage BeginTabular EndTabular BeginTable EndTable Horizontal

%start OUT

%expect 24 /* In Garbage and Text */

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
      | BeginTable BeginTabular Format Close Lines EndTabular Caption Open Text Close EndTable { $$ = new_table ($3, $5, $9); }
      | BeginTable Caption Open Text Close BeginTabular Format Close Lines EndTabular EndTable { $$ = new_table ($7, $9, $4); }
      ;

BeginTabular : Begin Open Tabular Close Open { $$ = NULL; }
             ;

EndTabular : End Open Tabular Close { $$ = NULL; }
           ;

BeginTable : Begin Open TableTok Close { $$ = NULL; }
           | Begin Open TableTok Close Text { $$ = NULL; }
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
           | CLine Open Text Close { $$ = NULL; }
           ;

Line : Text {
           CellContent cc = { .string = $1 };
           $$ = new_cell (STRING, cc, 1, '\0', NULL);
       }
     | Text NewCell Line {
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
     | MultiColumn Open Number Close Open Format Close Open Text Close {
           CellContent cc = { .string = $9 };
           $$ = new_cell (STRING, cc, $3, $6[0], NULL);
       }
     | MultiColumn Open Number Close Open Format Close Open Text Close NewCell Line {
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

Text : String { $$ = $1; }
     | Alpha  { $$ = strdup ("&alpha;"); }
     | ALPHA  { $$ = strdup ("&Alpha;"); }
     | Beta   { $$ = strdup ("&beta;");  }
     | BETA   { $$ = strdup ("&Beta;");  }
     | Gamma  { $$ = strdup ("&gamma;"); }
     | GAMMA  { $$ = strdup ("&Gamma;"); }
     | Delta  { $$ = strdup ("&delta;"); }
     | DELTA  { $$ = strdup ("&Delta;"); }
     /* The following rules causes each one 2 shift/reduce warnings */
     | Text String {
           $1 = (char *) realloc ($1, (strlen ($1) + strlen ($2) + 1) * sizeof (char));
           strcat ($1, $2);
           free ($2);
           $$ = $1;
       }
     | Text Alpha {
           $1 = (char *) realloc ($1, (strlen ($1) + 8) * sizeof (char));
           strcat ($1, "&alpha;");
           $$ = $1;
       }
     | Text ALPHA {
           $1 = (char *) realloc ($1, (strlen ($1) + 8) * sizeof (char));
           strcat ($1, "&Alpha;");
           $$ = $1;
       }
     | Text Beta {
           $1 = (char *) realloc ($1, (strlen ($1) + 7) * sizeof (char));
           strcat ($1, "&beta;");
           $$ = $1;
       }
     | Text BETA {
           $1 = (char *) realloc ($1, (strlen ($1) + 7) * sizeof (char));
           strcat ($1, "&Beta;");
           $$ = $1;
       }
     | Text Delta {
           $1 = (char *) realloc ($1, (strlen ($1) + 8) * sizeof (char));
           strcat ($1, "&delta;");
           $$ = $1;
       }
     | Text DELTA {
           $1 = (char *) realloc ($1, (strlen ($1) + 8) * sizeof (char));
           strcat ($1, "&Delta;");
           $$ = $1;
       }
     | Text Gamma {
           $1 = (char *) realloc ($1, (strlen ($1) + 8) * sizeof (char));
           strcat ($1, "&gamma;");
           $$ = $1;
       }
     | Text GAMMA {
           $1 = (char *) realloc ($1, (strlen ($1) + 8) * sizeof (char));
           strcat ($1, "&Gamma;");
           $$ = $1;
       }
     ;

Garbage : Text { $$ = NULL; }
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
        | LatexDirective { $$ = NULL; }
        /* The two following rules cause shift/reduce warnings... */
        | Begin Open Text Close { $$ = NULL; }
        | End Open Text Close { $$ = NULL; }
        | Garbage Text { $$ = NULL; }
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
        | Garbage LatexDirective { $$ = NULL; }
        /* The two following rules cause shift/reduce warnings... */
        | Garbage Begin Open Text Close { $$ = NULL; }
        | Garbage End Open Text Close { $$ = NULL; }
        ;
%%

