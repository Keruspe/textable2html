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

%token <string> String Number Format Blank
%token Begin End Open Close Tabular TableTok NewLine NewCell HLine CLine MultiColumn Caption LatexDirective
%token Alpha ALPHA Beta BETA Gamma GAMMA Delta DELTA
%token Bold Italic SmallCaps Roman Serif

%type <line> Lines
%type <cell> Line
%type <table> Table
%type <string> Text
%type <dummy> Garbage BeginTabular EndTabular BeginTable EndTable Horizontal BeginDummyRule EndDummyRule

%start OUT

%expect 70 /* In Garbage and mostly in Text */

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
      | BeginTable BeginDummyRule BeginTabular Format Close Lines EndTabular EndDummyRule EndTable { $$ = new_table ($4, $6, NULL); }
      | BeginTable BeginDummyRule BeginTabular Format Close Lines EndTabular EndDummyRule Caption Open Text Close EndTable { $$ = new_table ($4, $6, $11); }
      | BeginTable Caption Open Text Close BeginDummyRule BeginTabular Format Close Lines EndTabular EndDummyRule EndTable { $$ = new_table ($8, $10, $4); }
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

BeginDummyRule : Begin Open Text Close {
                     free ($3);
                     $$ = NULL;
                 }
               ;

EndDummyRule : End Open Text Close {
                   free ($3);
                   $$ = NULL;
               }
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
           | HLine Open Close { $$ = NULL; }
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
           CellContent cc = { .number = atof ($1) };
           free ($1);
           $$ = new_cell (NUMBER, cc, 1, '\0', NULL);
       }
     | Number NewCell Line {
           CellContent cc = { .number = atof ($1) };
           free ($1);
           $$ = new_cell (NUMBER, cc, 1, '\0', $3);
       }
     | MultiColumn Open Number Close Open Format Close Open Text Close {
           CellContent cc = { .string = $9 };
           $$ = new_cell (STRING, cc, atof ($3), $6[0], NULL);
           free ($3);
       }
     | MultiColumn Open Number Close Open Format Close Open Text Close NewCell Line {
           CellContent cc = { .string = $9 };
           $$ = new_cell (STRING, cc, atof ($3), $6[0], $12);
           free ($3);
       }
     | MultiColumn Open Number Close Open Format Close Open Number Close {
           CellContent cc = { .number = atof ($9) };
           free ($9);
           $$ = new_cell (NUMBER, cc, atof ($3), $6[0], NULL);
           free ($3);
       }
     | MultiColumn Open Number Close Open Format Close Open Number Close NewCell Line {
           CellContent cc = { .number = atof ($9) };
           free ($9);
           $$ = new_cell (NUMBER, cc, atof ($3), $6[0], $12);
           free ($3);
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
     | Blank  { $$ = $1; }
     | Alpha  { $$ = strdup ("&alpha;"); }
     | ALPHA  { $$ = strdup ("&Alpha;"); }
     | Beta   { $$ = strdup ("&beta;");  }
     | BETA   { $$ = strdup ("&Beta;");  }
     | Gamma  { $$ = strdup ("&gamma;"); }
     | GAMMA  { $$ = strdup ("&Gamma;"); }
     | Delta  { $$ = strdup ("&delta;"); }
     | DELTA  { $$ = strdup ("&Delta;"); }
     | Alpha Open Close   { $$ = strdup ("&alpha;"); }
     | ALPHA Open Close   { $$ = strdup ("&Alpha;"); }
     | Beta  Open Close   { $$ = strdup ("&beta;");  }
     | BETA  Open Close   { $$ = strdup ("&Beta;");  }
     | Gamma Open Close   { $$ = strdup ("&gamma;"); }
     | GAMMA Open Close   { $$ = strdup ("&Gamma;"); }
     | Delta Open Close   { $$ = strdup ("&delta;"); }
     | DELTA Open Close   { $$ = strdup ("&Delta;"); }
     | Bold Open Text Close {
           char *string = (char *) malloc ((strlen ($3) + 8) * sizeof (char));
           sprintf (string, "<b>%s</b>", $3);
           free ($3);
           $$ = string;
       }
     | Italic Open Text Close {
           char *string = (char *) malloc ((strlen ($3) + 10) * sizeof (char));
           sprintf (string, "<em>%s</em>", $3);
           free ($3);
           $$ = string;
       }
     | SmallCaps Open Text Close { $$ = make_caps ($3); }
     | Roman Open Text Close { $$ = $3; }
     | Serif Open Text Close { $$ = $3; }
     /* The following rules causes each one 2 shift/reduce warnings */
     | Text String {
           $1 = (char *) realloc ($1, (strlen ($1) + strlen ($2) + 1) * sizeof (char));
           strcat ($1, $2);
           free ($2);
           $$ = $1;
       }
     | Text Blank {
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
     | Text Alpha Open Close {
           $1 = (char *) realloc ($1, (strlen ($1) + 8) * sizeof (char));
           strcat ($1, "&alpha;");
           $$ = $1;
       }
     | Text ALPHA Open Close {
           $1 = (char *) realloc ($1, (strlen ($1) + 8) * sizeof (char));
           strcat ($1, "&Alpha;");
           $$ = $1;
       }
     | Text Beta Open Close {
           $1 = (char *) realloc ($1, (strlen ($1) + 7) * sizeof (char));
           strcat ($1, "&beta;");
           $$ = $1;
       }
     | Text BETA Open Close {
           $1 = (char *) realloc ($1, (strlen ($1) + 7) * sizeof (char));
           strcat ($1, "&Beta;");
           $$ = $1;
       }
     | Text Gamma Open Close {
           $1 = (char *) realloc ($1, (strlen ($1) + 8) * sizeof (char));
           strcat ($1, "&gamma;");
           $$ = $1;
       }
     | Text GAMMA Open Close {
           $1 = (char *) realloc ($1, (strlen ($1) + 8) * sizeof (char));
           strcat ($1, "&Gamma;");
           $$ = $1;
       }
     | Text Delta Open Close {
           $1 = (char *) realloc ($1, (strlen ($1) + 8) * sizeof (char));
           strcat ($1, "&delta;");
           $$ = $1;
       }
     | Text DELTA Open Close {
           $1 = (char *) realloc ($1, (strlen ($1) + 8) * sizeof (char));
           strcat ($1, "&Delta;");
           $$ = $1;
       }
     | Text Bold Open Text Close {
           char *string = (char *) malloc ((strlen ($1) + strlen ($4) + 8) * sizeof (char));
           sprintf (string, "%s<b>%s</b>", $1, $4);
           free ($4);
           $$ = string;
       }
     | Text Italic Open Text Close {
           char *string = (char *) malloc ((strlen ($1) + strlen ($4) + 10) * sizeof (char));
           sprintf (string, "%s<em>%s</em>", $1, $4);
           free ($4);
           $$ = string;
       }
     | Text SmallCaps Open Text Close {
           $1 = (char *) realloc ($1, (strlen ($1) + strlen ($4) + 1) * sizeof (char));
           strcat ($1, make_caps ($4));
           free ($4);
           $$ = $1;
       }
     | Text Roman Open Text Close {
           $1 = (char *) realloc ($1, (strlen ($1) + strlen ($4) + 1) * sizeof (char));
           strcat ($1, $4);
           free ($4);
           $$ = $1;
       }
     | Text Serif Open Text Close {
           $1 = (char *) realloc ($1, (strlen ($1) + strlen ($4) + 1) * sizeof (char));
           strcat ($1, $4);
           free ($4);
           $$ = $1;
       }
     /* There can be a number in the middle of a Text. the second rule causes 17 shift/reduce warnings */
     | Text Number {
           $1 = (char *) realloc ($1, (strlen ($1) + strlen ($2) + 1) * sizeof (char));
           strcat ($1, $2);
           free ($2);
           $$ = $1;
       }
     | Number Text {
           $1 = (char *) realloc ($1, (strlen ($1) + strlen ($2) + 1) * sizeof (char));
           strcat ($1, $2);
           free ($2);
           $$ = $1;
       }
     ;

Garbage : Text {
              free ($1);
              $$ = NULL;
          }
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
        | BeginDummyRule { $$ = NULL; }
        | EndDummyRule { $$ = NULL; }
        | Garbage Text {
              free ($2);
              $$ = NULL;
          }
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
        | Garbage BeginDummyRule { $$ = NULL; }
        | Garbage EndDummyRule { $$ = NULL; }
        ;
%%

