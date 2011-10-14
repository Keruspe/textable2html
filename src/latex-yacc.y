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
            exit (0);
      }
    | Table Garbage {
            htmlize ($1);
            exit (0);
      }
    | Garbage Table Garbage {
            htmlize ($2);
            exit (0);
      }
    | Table {
            htmlize ($1);
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
           | Begin Open TableTok Close Text {
                 $$ = NULL;
                 free ($5);
             }
           ;

EndTable : End Open TableTok Close { $$ = NULL; }
         ;

BeginDummyRule : Begin Open Text Close {
                     $$ = NULL;
                     free ($3);
                 }
               ;

EndDummyRule : End Open Text Close {
                   $$ = NULL;
                   free ($3);
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
           | CLine Open Text Close {
                 $$ = NULL;
                 free ($3);
             }
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
           $$ = new_cell (NUMBER, cc, 1, '\0', NULL);
           free ($1);
       }
     | Number NewCell Line {
           CellContent cc = { .number = atof ($1) };
           $$ = new_cell (NUMBER, cc, 1, '\0', $3);
           free ($1);
       }
     | MultiColumn Open Number Close Open Format Close Open Text Close {
           CellContent cc = { .string = $9 };
           $$ = new_cell (STRING, cc, atof ($3), $6[0], NULL);
           free ($3);
           free ($6);
       }
     | MultiColumn Open Number Close Open Format Close Open Text Close NewCell Line {
           CellContent cc = { .string = $9 };
           $$ = new_cell (STRING, cc, atof ($3), $6[0], $12);
           free ($3);
           free ($6);
       }
     | MultiColumn Open Number Close Open Format Close Open Number Close {
           CellContent cc = { .number = atof ($9) };
           $$ = new_cell (NUMBER, cc, atof ($3), $6[0], NULL);
           free ($3);
           free ($6);
           free ($9);
       }
     | MultiColumn Open Number Close Open Format Close Open Number Close NewCell Line {
           CellContent cc = { .number = atof ($9) };
           $$ = new_cell (NUMBER, cc, atof ($3), $6[0], $12);
           free ($3);
           free ($6);
           free ($9);
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
     | Bold Open Text Close { $$ = surround_with ($3, "b"); }
     | Italic Open Text Close { $$ = surround_with ($3, "i"); }
     | SmallCaps Open Text Close { $$ = make_caps ($3); }
     | Roman Open Text Close { $$ = $3; }
     | Serif Open Text Close { $$ = $3; }
     /* The following rules causes each one 2 shift/reduce warnings */
     | Text String { $$ = append ($1, $2); }
     | Text Blank { $$ = append ($1, $2); }
     | Text Alpha { $$ = append_const ($1, "&alpha;"); }
     | Text ALPHA { $$ = append_const ($1, "&Alpha;"); }
     | Text Beta { $$ = append_const ($1, "&beta;"); }
     | Text BETA { $$ = append_const ($1, "&Beta;"); }
     | Text Gamma { $$ = append_const ($1, "&gamma;"); }
     | Text GAMMA { $$ = append_const ($1, "&Gamma;"); }
     | Text Delta { $$ = append_const ($1, "&delta;"); }
     | Text DELTA { $$ = append_const ($1, "&Delta;"); }
     | Text Alpha Open Close { $$ = append_const ($1, "&alpha;"); }
     | Text ALPHA Open Close { $$ = append_const ($1, "&Alpha;"); }
     | Text Beta Open Close { $$ = append_const ($1, "&beta;"); }
     | Text BETA Open Close { $$ = append_const ($1, "&Beta;"); }
     | Text Gamma Open Close { $$ = append_const ($1, "&gamma;"); }
     | Text GAMMA Open Close { $$ = append_const ($1, "&Gamma;"); }
     | Text Delta Open Close { $$ = append_const ($1, "&delta;"); }
     | Text DELTA Open Close { $$ = append_const ($1, "&Delta;"); }
     | Text Bold Open Text Close { $$ = append ($1, surround_with ($4, "b")); }
     | Text Italic Open Text Close { $$ = append ($1, surround_with ($4, "i")); }
     | Text SmallCaps Open Text Close { $$ = append ($1, make_caps ($4)); }
     | Text Roman Open Text Close { $$ = append ($1, $4); }
     | Text Serif Open Text Close { $$ = append ($1, $4); }
     /* There can be a number in the middle of a Text. the second rule causes 17 shift/reduce warnings */
     | Text Number { $$ = append ($1, $2); }
     | Number Text { $$ = append ($1, $2); }
     ;

Garbage : Text {
              $$ = NULL;
              free ($1);
          }
        | Format {
              $$ = NULL;
              free ($1);
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
              $$ = NULL;
              free ($2);
          }
        | Garbage Format {
              $$ = NULL;
              free ($2);
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

