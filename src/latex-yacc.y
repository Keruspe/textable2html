%{
    #include "latextohtml.h"

    int yylex ();
    void yyerror (char *error);
%}

%union {
    struct _Line  *line;
    struct _Cell  *cell;
    struct _Table *table;
    int   integer;
    char *string;
    void *dummy;
}

%token <string> String Number Integer Format Blank
%token Begin End Open Close Tabular TableTok
%token NewLine NewCell HLine CLine MultiColumnTok CaptionTok LatexDirective
%token Alpha ALPHA Beta BETA Gamma GAMMA Delta DELTA
%token Bold Italic SmallCaps Roman Serif

%type <line> Lines
%type <cell> Line
%type <table> Table GarbageLessTable
%type <integer> MultiColumn
%type <string> Text Caption
%type <dummy> Garbage BeginTabular EndTabular BeginTable EndTable Horizontal
%type <dummy> BeginDummyRule EndDummyRule DummyText

%start OUT

%expect 168 /* In Garbage and mostly in Text */

%%
OUT: GarbageLessTable {
         htmlize ($1);
         exit (0);
     }

GarbageLessTable :         Table         { $$ = $1; }
                 |         Table Garbage { $$ = $1; }
                 | Garbage Table         { $$ = $2; }
                 | Garbage Table Garbage { $$ = $2; }
                 ;

Table :            BeginTabular Format Close Lines EndTabular                  { $$ = new_table ($2, $4, NULL); }
      | BeginTable BeginTabular Format Close Lines EndTabular EndTable         { $$ = new_table ($3, $5, NULL); }
      | BeginTable BeginTabular Format Close Lines EndTabular Caption EndTable { $$ = new_table ($3, $5, $7);   }
      | BeginTable Caption BeginTabular Format Close Lines EndTabular EndTable { $$ = new_table ($4, $6, $2);   }
      | BeginTable BeginDummyRule BeginTabular Format Close Lines EndTabular EndDummyRule EndTable         { $$ = new_table ($4, $6, NULL); }
      | BeginTable BeginDummyRule BeginTabular Format Close Lines EndTabular EndDummyRule Caption EndTable { $$ = new_table ($4, $6, $9);   }
      | BeginTable Caption BeginDummyRule BeginTabular Format Close Lines EndTabular EndDummyRule EndTable { $$ = new_table ($5, $7, $2);   }
      ;

Caption : CaptionTok Open Text Close { $$ = $3; }
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

BeginDummyRule : Begin DummyText { $$ = NULL; }
               ;

EndDummyRule : End DummyText { $$ = NULL; }
             ;

Lines : Line               { $$ = new_line ($1, NULL); }
      | Line NewLine       { $$ = new_line ($1, NULL); }
      | Line NewLine Lines { $$ = new_line ($1, $3);   }
      | Horizontal               { $$ = NULL; }
      | Horizontal Lines         { $$ = $2;   }
      | Horizontal NewLine       { $$ = NULL; }
      | Horizontal NewLine Lines { $$ = $3;   }
      ;

Horizontal : HLine            { $$ = NULL; }
           | HLine Open Close { $$ = NULL; }
           | CLine DummyText  { $$ = NULL; }
           ;

DummyText : Open Text Close {
                $$ = NULL;
                free ($2);
            }

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
     | Integer {
           CellContent cc = { .integer = atoi ($1) };
           $$ = new_cell (INTEGER, cc, 1, '\0', NULL);
           free ($1);
       }
     | Integer NewCell Line {
           CellContent cc = { .integer = atoi ($1) };
           $$ = new_cell (INTEGER, cc, 1, '\0', $3);
           free ($1);
       }
     | MultiColumn Format Close Open Text Close {
           CellContent cc = { .string = $5 };
           $$ = new_cell (STRING, cc, $1, $2[0], NULL);
           free ($2);
       }
     | MultiColumn Format Close Open Text Close NewCell Line {
           CellContent cc = { .string = $5 };
           $$ = new_cell (STRING, cc, $1, $2[0], $8);
           free ($2);
       }
     | MultiColumn Format Close Open Number Close {
           CellContent cc = { .number = atof ($5) };
           $$ = new_cell (NUMBER, cc, $1, $2[0], NULL);
           free ($2);
           free ($5);
       }
     | MultiColumn Format Close Open Number Close NewCell Line {
           CellContent cc = { .number = atof ($5) };
           $$ = new_cell (NUMBER, cc, $1, $2[0], $8);
           free ($2);
           free ($5);
       }
     | MultiColumn Format Close Open Integer Close {
           CellContent cc = { .integer = atoi ($5) };
           $$ = new_cell (INTEGER, cc, $1, $2[0], NULL);
           free ($2);
           free ($5);
       }
     | MultiColumn Format Close Open Integer Close NewCell Line {
           CellContent cc = { .integer = atoi ($5) };
           $$ = new_cell (INTEGER, cc, $1, $2[0], $8);
           free ($2);
           free ($5);
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

MultiColumn : MultiColumnTok Open Integer Close Open {
                  $$ = atoi ($3);
                  free ($3);
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
     | Alpha Open Close { $$ = strdup ("&alpha;"); }
     | ALPHA Open Close { $$ = strdup ("&Alpha;"); }
     | Beta  Open Close { $$ = strdup ("&beta;");  }
     | BETA  Open Close { $$ = strdup ("&Beta;");  }
     | Gamma Open Close { $$ = strdup ("&gamma;"); }
     | GAMMA Open Close { $$ = strdup ("&Gamma;"); }
     | Delta Open Close { $$ = strdup ("&delta;"); }
     | DELTA Open Close { $$ = strdup ("&Delta;"); }
     | Bold      Open Text Close { $$ = surround_with ($3, "b"); }
     | Italic    Open Text Close { $$ = surround_with ($3, "i"); }
     | SmallCaps Open Text Close { $$ = make_caps ($3); }
     | Roman     Open Text Close { $$ = $3; }
     | Serif     Open Text Close { $$ = $3; }
     /* The following rules causes each one 2 shift/reduce warnings */
     | Text String { $$ = append ($1, $2); }
     | Text Blank  { $$ = append ($1, $2); }
     | Text Alpha  { $$ = append_const ($1, "&alpha;"); }
     | Text ALPHA  { $$ = append_const ($1, "&Alpha;"); }
     | Text Beta   { $$ = append_const ($1, "&beta;");  }
     | Text BETA   { $$ = append_const ($1, "&Beta;");  }
     | Text Gamma  { $$ = append_const ($1, "&gamma;"); }
     | Text GAMMA  { $$ = append_const ($1, "&Gamma;"); }
     | Text Delta  { $$ = append_const ($1, "&delta;"); }
     | Text DELTA  { $$ = append_const ($1, "&Delta;"); }
     | Text Alpha Open Close { $$ = append_const ($1, "&alpha;"); }
     | Text ALPHA Open Close { $$ = append_const ($1, "&Alpha;"); }
     | Text Beta  Open Close { $$ = append_const ($1, "&beta;");  }
     | Text BETA  Open Close { $$ = append_const ($1, "&Beta;");  }
     | Text Gamma Open Close { $$ = append_const ($1, "&gamma;"); }
     | Text GAMMA Open Close { $$ = append_const ($1, "&Gamma;"); }
     | Text Delta Open Close { $$ = append_const ($1, "&delta;"); }
     | Text DELTA Open Close { $$ = append_const ($1, "&Delta;"); }
     | Text Bold      Open Text Close { $$ = append ($1, surround_with ($4, "b")); }
     | Text Italic    Open Text Close { $$ = append ($1, surround_with ($4, "i")); }
     | Text SmallCaps Open Text Close { $$ = append ($1, make_caps ($4)); }
     | Text Roman     Open Text Close { $$ = append ($1, $4); }
     | Text Serif     Open Text Close { $$ = append ($1, $4); }
     /* There can be a number in the middle of a Text. the second rule causes 17 shift/reduce warnings */
     | Text Number { $$ = append ($1, $2); }
     | Number Text { $$ = append ($1, $2); }
     /* There can be an integer in the middle of a Text. the second rule causes 19 shift/reduce warnings */
     | Text Integer { $$ = append ($1, $2); }
     | Integer Text { $$ = append ($1, $2); }
     ;

Garbage : Text {
              $$ = NULL;
              free ($1);
          }
        | Format {
              $$ = NULL;
              free ($1);
          }
        /* The two following rules causes 17 shift/reduce warnings each */
        | Number {
              $$ = NULL;
              free ($1);
          }
        | Integer {
              $$ = NULL;
              free ($1);
          }
        | NewLine    { $$ = NULL; }
        | NewCell    { $$ = NULL; }
        | Begin      { $$ = NULL; }
        | End        { $$ = NULL; }
        | Open       { $$ = NULL; }
        | Close      { $$ = NULL; }
        | CaptionTok { $$ = NULL; }
        | TableTok   { $$ = NULL; }
        | Tabular    { $$ = NULL; }
        | HLine      { $$ = NULL; }
        | CLine      { $$ = NULL; }
        | Bold       { $$ = NULL; }
        | Italic     { $$ = NULL; }
        | SmallCaps  { $$ = NULL; }
        | Roman      { $$ = NULL; }
        | Serif      { $$ = NULL; }
        | MultiColumn    { $$ = NULL; }
        | LatexDirective { $$ = NULL; }
        /* The two following rules cause shift/reduce warnings... */
        | BeginDummyRule { $$ = NULL; }
        | EndDummyRule   { $$ = NULL; }
        | Garbage Text {
              $$ = NULL;
              free ($2);
          }
        | Garbage Format {
              $$ = NULL;
              free ($2);
          }
        /* The two following rules causes 17 shift/reduce warnings each */
        | Garbage Number {
              $$ = NULL;
              free ($2);
          }
        | Garbage Integer {
              $$ = NULL;
              free ($2);
          }
        | Garbage NewLine { $$ = NULL; }
        | Garbage NewCell { $$ = NULL; }
        | Garbage Begin   { $$ = NULL; }
        | Garbage End     { $$ = NULL; }
        /* The two following rules cause shift/reduce warnings... */
        | Garbage Open       { $$ = NULL; }
        | Garbage Close      { $$ = NULL; }
        | Garbage CaptionTok { $$ = NULL; }
        | Garbage TableTok   { $$ = NULL; }
        | Garbage Tabular    { $$ = NULL; }
        | Garbage HLine      { $$ = NULL; }
        | Garbage CLine      { $$ = NULL; }
        | Garbage Bold       { $$ = NULL; }
        | Garbage Italic     { $$ = NULL; }
        | Garbage SmallCaps  { $$ = NULL; }
        | Garbage Roman      { $$ = NULL; }
        | Garbage Serif      { $$ = NULL; }
        | Garbage MultiColumn    { $$ = NULL; }
        | Garbage LatexDirective { $$ = NULL; }
        /* The two following rules cause shift/reduce warnings... */
        | Garbage BeginDummyRule { $$ = NULL; }
        | Garbage EndDummyRule   { $$ = NULL; }
        ;
%%

