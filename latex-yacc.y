%{
    #include <stdio.h>
    #include <stdlib.h>

    extern FILE * yyin;
    void yyerror (char * error);
    int yyparse ();
    extern int yylex (void);
    extern int yylex_destroy(void);

    typedef enum {
        NUMBER,
        STRING
    } CellKind;

    typedef struct Cell {
        CellKind kind;
        union {
            char *string;
            float number;
        } content;
        struct Cell *next;
    } Cell;

    typedef struct Line {
        Cell *cells;
        struct Line *next;
    } Line;

    typedef enum {
        COL = 'c',
        LEFT = 'l',
        RIGHT = 'r',
        SEP = '|'
    } FormatKind;

    typedef struct Format {
        FormatKind kind;
        struct Format *next;
    } Format;

    void printlines(Line *l) {
        Cell *cell;
        printf("<table>\n");
        while (l) {
            printf("    <tr>\n");
            cell = l->cells;
            while (cell) {
                printf("        <td>");
                switch (cell->kind) {
                case NUMBER:
                    printf("%f", cell->content.number);
                    break;
                case STRING:
                    printf("%s", cell->content.string);
                }
                printf("</td>\n");
                cell = cell->next;
            }
            printf("    </tr>\n");
            l = l->next;
        }
        printf("</table>");
    }

    void freelines(Line *l) {
        Cell *cell;
        while (l) {
            Line *t = l->next;
            cell = l->cells;
            while (cell) {
                Cell *tmp = cell->next;
                switch (cell->kind) {
                case STRING:
                    free(cell->content.string);
                case NUMBER:
                    free(cell);
                }
                cell = tmp;
            }
            free(l);
            l = t;
        }
    }

    void printFormat(Format *f) {
        while(f) {
            printf("%c", f->kind);
            f = f->next;
        }
        printf("\n");
    }

    void freeFormat(Format *f) {
        while(f) {
            Format *next = f->next;
            free(f);
            f = next;
        }
    }
%}

%union { float fval; char cval; char * sval; struct Line * line; struct Cell * cell; void * noval; struct Format * format; }
%token <fval>  Number
%token <sval>  String
%token <cval> FormatPiece
%token OpenBeginTab CloseBeginTab EndTab NewLine NewCell

%type <line>  Table
%type <line>  Lines
%type <cell>  Line
%type <cell>  Cell
%type <format> Format
%type <noval> Garbage
%start OUT

%%
OUT : Garbage Table { exit(0); }
    | Table Garbage { exit(0); }
    | Garbage Table Garbage { exit(0); }
    | Table { exit(0); }
    ;

Table : OpenBeginTab Format CloseBeginTab Lines EndTab { printf("Format:\n"); printFormat($2); printf("Content:\n"); printlines($4); freeFormat($2); freelines($4); }
      ;

Format : FormatPiece { Format *f = (Format *) malloc(sizeof(Format)); f->next = NULL; f->kind = $1; $$ = f; }
       | FormatPiece Format { Format *f = (Format *) malloc(sizeof(Format)); f->next = $2; f->kind = $1; $$ = f; }
       ;

Lines : Line { Line *l = (Line *) malloc(sizeof(Line)); l->cells = $1; l->next = NULL; $$ = l; }
      | Line NewLine Lines { Line *l = (Line *) malloc(sizeof(Line)); l->cells = $1; l->next = $3; $$ = l; }
      ;

Line : Cell { Cell *c = $1; c->next = NULL; $$ = c; }
     | Cell NewCell Line  { Cell *c = $1; c->next = $3; $$ = c; }
     ;

Cell : String { Cell *c = (Cell *) malloc(sizeof(Cell)); c->kind = STRING; c->content.string = $1; $$ = c; }
     | Number { Cell *c = (Cell *) malloc(sizeof(Cell)); c->kind = NUMBER; c->content.number = $1; $$ = c; }
     ;

Garbage : String { $$ = NULL; }
        | Number { $$ = NULL; }
        | NewLine { $$ = NULL; }
        | NewCell { $$ = NULL; }
        | Garbage String { $$ = NULL; }
        | Garbage Number { $$ = NULL; }
        | Garbage NewLine { $$ = NULL; }
        | Garbage NewCell { $$ = NULL; }
        ;
%%

void
yyerror(char * error)
{
    fprintf(stderr, "Error : %s\n", error);
    yylex_destroy();
    exit (1);
}

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf (stderr, "usage: %s <file>\n", argv[0]);
        yyerror ("bad invocation");
    }
    yyin = fopen(argv[1], "r");
    yyparse();
    yylex_destroy();
    fclose (yyin);
    return 0;
}



