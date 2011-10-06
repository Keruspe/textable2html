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

    typedef struct Table {
        Format *format;
        Line *lines;
    } Table;

    void printFormat(Format *f) {
        printf("Format: ");
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

    void printTable(Table *t) {
        printFormat(t->format);
        Line *l = t->lines;
        printf("<table>\n");
        while (l) {
            printf("    <tr>\n");
            Cell *cell = l->cells;
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
        printf("</table>\n");
    }

    void freeTable(Table *t) {
        freeFormat(t->format);
        Line *l = t->lines;
        while (l) {
            Line *next = l->next;
            Cell *cell = l->cells;
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
            l = next;
        }
        free(t);
    }

    Table *newTable(Format *format, Line *lines) {
        Table *t = (Table *) malloc(sizeof(Table));
        t->format = format;
        t->lines = lines;
        return t;
    }

    Format *newFormat(FormatKind kind, Format *next) {
        Format *f = (Format *) malloc(sizeof(Format));
        f->kind = kind;
        f->next = next;
        return f;
    }

    Line *newLine(Cell *cells, Line *next) {
        Line *l = (Line *) malloc(sizeof(Line));
        l->cells = cells;
        l->next = next;
        return l;
    }

    Cell *newCell(CellKind kind) {
        Cell *c = (Cell *) malloc(sizeof(Cell));
        c->kind = kind;
        return c;
    }
%}

%union {
    float number;
    char character;
    char *string;
    struct Line *line;
    struct Cell *cell;
    struct Format *format;
    struct Table *table;
    void *dummy;
}

%token <number> Number
%token <string> String
%token <character> FormatPiece
%token OpenBeginTab CloseBeginTab EndTab NewLine NewCell

%type <line> Lines
%type <cell> Line Cell
%type <format> Format
%type <table> Table
%type <dummy> Garbage

%start OUT

%%
OUT : Garbage Table {
            printTable($2);
            freeTable($2);
            exit(0);
      }
    | Table Garbage {
            printTable($1);
            freeTable($1);
            exit(0);
      }
    | Garbage Table Garbage {
            printTable($2);
            freeTable($2);
            exit(0);
      }
    | Table {
            printTable($1);
            freeTable($1);
            exit(0);
      }
    ;

Table : OpenBeginTab Format CloseBeginTab Lines EndTab { $$ = newTable($2, $4); }
      ;

Format : FormatPiece { $$ = newFormat($1, NULL); }
       | FormatPiece Format { $$ = newFormat($1, $2); }
       ;

Lines : Line { $$ = newLine($1, NULL); }
      | Line NewLine Lines { $$ = newLine($1, $3); }
      ;

Line : Cell {
            Cell *c = $1;
            c->next = NULL;
            $$ = c;
       }
     | Cell NewCell Line  {
            Cell *c = $1;
            c->next = $3;
            $$ = c;
       }
     ;

Cell : String {
            Cell *c = newCell(STRING);
            c->content.string = $1;
            $$ = c;
       }
     | Number {
            Cell *c = newCell(NUMBER);
            c->content.number = $1;
            $$ = c;
       }
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


