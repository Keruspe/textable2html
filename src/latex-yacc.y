%{
    #include "latextohtml.h"

    int yylex ();
    void yyerror (char *error);
%}

%union {
    struct _Line  *lines;
    struct _Cell  *cells;
    struct _Table *table;
    int   integer;
    float number;
    char  character;
    char *string;
    void *dummy;
}

%token <string> String NumberTok IntegerTok Format Blank
%token Begin End Open Close Tabular TableTok
%token NewLine NewCell HLine CLine MultiColumnTok CaptionTok LatexDirective
%token Alpha ALPHA Beta BETA Gamma GAMMA Delta DELTA
%token Bold Italic SmallCaps Roman Serif Emphasis

%type <lines> Lines
%type <cells> Line
%type <table> Table GarbageLessTable
%type <integer> MultiColumn Integer
%type <number> Number
%type <character> SimpleFormat
%type <string> Text Caption
%type <dummy> Garbage BeginTabular EndTabular BeginTable EndTable Horizontal
%type <dummy> BeginDummyRule EndDummyRule DummyText

%start OUT

%expect 123 /* In Garbage and mostly in Text */

%%
OUT: GarbageLessTable {
         /* Generate html and exit */
         htmlize ($1);
         exit (0);
     }

/* This is to ignore the garbage before and after the table */
GarbageLessTable :         Table         { $$ = $1; }
                 |         Table Garbage { $$ = $1; }
                 | Garbage Table         { $$ = $2; }
                 | Garbage Table Garbage { $$ = $2; }
                 ;

/* A table can either be a tabular, or a tabular in a table or a tabular in something like a center block, and there can be a caption in it */
Table :            BeginTabular Format Close Lines EndTabular                  { $$ = new_table ($2, $4, NULL); }
      | BeginTable BeginTabular Format Close Lines EndTabular EndTable         { $$ = new_table ($3, $5, NULL); }
      | BeginTable BeginTabular Format Close Lines EndTabular Caption EndTable { $$ = new_table ($3, $5, $7);   }
      | BeginTable Caption BeginTabular Format Close Lines EndTabular EndTable { $$ = new_table ($4, $6, $2);   }
      | BeginTable BeginDummyRule BeginTabular Format Close Lines EndTabular EndDummyRule EndTable         { $$ = new_table ($4, $6, NULL); }
      | BeginTable BeginDummyRule BeginTabular Format Close Lines EndTabular EndDummyRule Caption EndTable { $$ = new_table ($4, $6, $9);   }
      | BeginTable Caption BeginDummyRule BeginTabular Format Close Lines EndTabular EndDummyRule EndTable { $$ = new_table ($5, $7, $2);   }
      ;

/* A table opening can be followed by stuff like [c], just ignore it */
BeginTable : Begin Open TableTok Close           { $$ = NULL; }
           | Begin Open TableTok Close DummyText { $$ = NULL; }
           ;

/* The following rules are separated rules for readability concerns */
BeginDummyRule : Begin Open DummyText Close { $$ = NULL; }
               ;

BeginTabular : Begin Open Tabular Close Open { $$ = NULL; }
             ;

EndTabular : End Open Tabular Close { $$ = NULL; }
           ;

EndDummyRule : End Open DummyText Close { $$ = NULL; }
             ;

Caption : CaptionTok Open Text Close { $$ = $3; }
        ;

EndTable : End Open TableTok Close { $$ = NULL; }
         ;

DummyText : Text {
                $$ = NULL;
                free ($1);
            }

/* The actual table content. Lines are separated by newline and/or horizontal lines */
Lines : Line               { $$ = new_line ($1, NULL); }
      | Line NewLine       { $$ = new_line ($1, NULL); }
      | Line NewLine Lines { $$ = new_line ($1, $3);   }
      | Horizontal               { $$ = NULL; }
      | Horizontal Lines         { $$ = $2;   }
      | Horizontal NewLine       { $$ = NULL; }
      | Horizontal NewLine Lines { $$ = $3;   }
      ;

/* An horizontal line can either be a \hline or a \cline */
Horizontal : HLine            { $$ = NULL; }
           | HLine Open Close { $$ = NULL; }
           | CLine Open DummyText Close  { $$ = NULL; }
           ;

/* A line can be one or many cells (which can be empty) separated by newcell (&) */
/* Simple cells are either text, or integers, or numbers */
/* A multicolumn has a simpleformat (unichar format) and a content as for a simple one */
Line : Text                 { $$ = new_string_cell ($1, 1, '\0', NULL);  }
     | Text    NewCell Line { $$ = new_string_cell ($1, 1, '\0', $3);    }
     | Number               { $$ = new_number_cell ($1, 1, '\0', NULL);  }
     | Number  NewCell Line { $$ = new_number_cell ($1, 1, '\0', $3);    }
     | Integer              { $$ = new_integer_cell ($1, 1, '\0', NULL); }
     | Integer NewCell Line { $$ = new_integer_cell ($1, 1, '\0', $3);   }
     | MultiColumn SimpleFormat Close Open Text    Close              { $$ = new_string_cell ($5, $1, $2, NULL);  }
     | MultiColumn SimpleFormat Close Open Text    Close NewCell Line { $$ = new_string_cell ($5, $1, $2, $8);    }
     | MultiColumn SimpleFormat Close Open Number  Close              { $$ = new_number_cell ($5, $1, $2, NULL);  }
     | MultiColumn SimpleFormat Close Open Number  Close NewCell Line { $$ = new_number_cell ($5, $1, $2, $8);    }
     | MultiColumn SimpleFormat Close Open Integer Close              { $$ = new_integer_cell ($5, $1, $2, NULL); }
     | MultiColumn SimpleFormat Close Open Integer Close NewCell Line { $$ = new_integer_cell ($5, $1, $2, $8);   }
     | NewCell      { $$ = new_string_cell (strdup (""), 1, '\0', NULL); }
     | NewCell Line { $$ = new_string_cell (strdup (""), 1, '\0', $2);   }
     ;

/* The following rules are separated for readability purpose */
SimpleFormat : Format {
                   $$ = $1[0];
                   free ($1);
               }
             ;

MultiColumn : MultiColumnTok Open Integer Close Open { $$ = $3; }
            ;

/* A text can be a string, a greek letter, a string with modifier and can contain numbers/integers */
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
     | Emphasis  Open Text Close { $$ = surround_with ($3, "em"); }
     | Bold      Open Text Close { $$ = surround_with ($3, "b");  }
     | Italic    Open Text Close { $$ = surround_with ($3, "i");  }
     | SmallCaps Open Text Close { $$ = make_caps ($3); }
     | Roman     Open Text Close { $$ = $3; }
     | Serif     Open Text Close { $$ = $3; }
     /* The following rules causes each one 2 shift/reduce warnings (some are common with others). Considering all others, it's worth 15 warnings */
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
     | Text Emphasis  Open Text Close { $$ = append ($1, surround_with ($4, "em")); }
     | Text Bold      Open Text Close { $$ = append ($1, surround_with ($4, "b"));  }
     | Text Italic    Open Text Close { $$ = append ($1, surround_with ($4, "i"));  }
     | Text SmallCaps Open Text Close { $$ = append ($1, make_caps ($4)); }
     | Text Roman     Open Text Close { $$ = append ($1, $4); }
     | Text Serif     Open Text Close { $$ = append ($1, $4); } 
     /* There can be a number in the middle of a Text. The first rule causes 3 shift/reduce warnings and the second 35 (37 for both) */
     | Text NumberTok { $$ = append ($1, $2); }
     | NumberTok Text { $$ = append ($1, $2); }
     /* There can be an integer in the middle of a Text. The first rule causes 3 shift/reduce warnings and the second 35 (37 for both) */
     | Text IntegerTok { $$ = append ($1, $2); }
     | IntegerTok Text { $$ = append ($1, $2); }
     /* The 4 preceding rules are woth 70 shift/reduce warnings */
     ;

/* This rule is made to consume everyting before and after the table. It can consume everyting but table opening/ending */
Garbage : DummyText { $$ = NULL; }
        | Format {
              $$ = NULL;
              free ($1);
          }
        | Number     { $$ = NULL; }
        | Integer    { $$ = NULL; }
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
        | Emphasis   { $$ = NULL; }
        | Bold       { $$ = NULL; }
        | Italic     { $$ = NULL; }
        | SmallCaps  { $$ = NULL; }
        | Roman      { $$ = NULL; }
        | Serif      { $$ = NULL; }
        | MultiColumn       { $$ = NULL; }
        | LatexDirective    { $$ = NULL; }
        /* The two following rules cause 1 shift/reduce warning each... */
        | BeginDummyRule    { $$ = NULL; }
        | EndDummyRule      { $$ = NULL; }
        | Garbage DummyText { $$ = NULL; }
        | Garbage Format {
              $$ = NULL;
              free ($2);
          }
        | Garbage Number     { $$ = NULL; }
        | Garbage Integer    { $$ = NULL; }
        | Garbage NewLine    { $$ = NULL; }
        | Garbage NewCell    { $$ = NULL; }
        | Garbage Begin      { $$ = NULL; }
        | Garbage End        { $$ = NULL; }
        /* The following rules causes 34 shift/reduce warnings... */
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
        /* The two following rules cause 1 shift/reduce warning each... */
        | Garbage BeginDummyRule { $$ = NULL; }
        | Garbage EndDummyRule   { $$ = NULL; }
        ;

/* As an integer or a number can be part of a text, we handle it as a string, this converts the string to a numerical value */
Integer : IntegerTok {
              $$ = atoi ($1);
              free ($1);
          }
        ;

Number : NumberTok {
             $$ = atof ($1);
             free ($1);
         }
       ;
%%

