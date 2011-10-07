%{
    #include <stdbool.h>
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>

    extern FILE * yyin;
    void yyerror (char * error);
    int yyparse ();
    extern int yylex (void);
    extern int yylex_destroy(void);

    bool numbers_only = true;

    typedef enum {
        NUMBER,
        STRING
    } CellKind;

    typedef union {
        char *string;
        float number;
    } CellContent;

    typedef struct Cell {
        CellKind kind;
        CellContent content;
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

    typedef struct Table {
        char *format;
        Line *lines;
        bool borders;
        int nb_cell;
    } Table;

    Table *newTable(char *format, Line *lines) {
        Table *t = (Table *) malloc(sizeof(Table));
        t->format = format;
        t->lines = lines;
        int nb_cell = 0, nb_sep = 0;
        for (unsigned int i = 0; i < strlen(format); ++i) {
            if (format[i] == SEP)
                ++nb_sep;
            else
                ++nb_cell;
        }
        t->borders = (nb_sep > nb_cell/2);
        t->nb_cell = nb_cell;
        return t;
    }

    Line *newLine(Cell *cells, Line *next) {
        Line *l = (Line *) malloc(sizeof(Line));
        l->cells = cells;
        l->next = next;
        return l;
    }

    Cell *newCell(CellKind kind, CellContent content, Cell *next) {
        Cell *c = (Cell *) malloc(sizeof(Cell));
        c->kind = kind;
        c->content = content;
        c->next = next;
        if (kind != NUMBER)
            numbers_only = false;
        return c;
    }

    void printTable(Table *t) {
        printf("<!DOCTYPE html>\n<html>\n    <head>\n        <title>Table</title>\n");
        if (t->borders)
            printf("        <style>\n            table { border-collapse: all; }\n            tr td { border: solid 1px; }\n        </style>\n");
        printf("    </head>\n    <body>\n");
        Line *l = t->lines;
        Cell *total = NULL;
        if (numbers_only) {
            for (int i = 0; i <= t->nb_cell; ++i) {
                CellContent cc = { .number = 0 };
                total = newCell(NUMBER, cc, total);
            }
        }
        printf("        <table>\n");
        while (l) {
            printf("            <tr>\n");
            Cell *cell = l->cells;
            Cell *current = total;
            int i;
            float sum = 0;
            for (i = 0; cell && i < t->nb_cell; ++i) {
                printf("                <td>");
                switch (cell->kind) {
                case NUMBER:
                    printf("%f", cell->content.number);
                    break;
                case STRING:
                    printf("%s", cell->content.string);
                }
                printf("</td>\n");
                if (numbers_only) {
                    sum += cell->content.number;
                    current->content.number += cell->content.number;
                    current = current->next;
                }
                cell = cell->next;
            }
            for (; i < t->nb_cell; ++i) {
                if (numbers_only)
                    current = current->next;
                printf("                <td></td>\n");
            }
            if (numbers_only) {
                current->content.number += sum;
                printf("                <td>%f</td>\n", sum);
            }
            printf("            </tr>\n");
            l = l->next;
        }
        if (numbers_only) {
            printf("            <tr>\n");
            while (total) {
                printf("                <td>%f</td>\n", total->content.number);
                Cell *tmp = total->next;
                free(total);
                total = tmp;
            }
            printf("            </tr>\n");
        }
        printf("        </table>\n    </body>\n</html>\n");
    }

    void freeTable(Table *t) {
        free(t->format);
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
%token OpenBeginTab CloseBeginTab EndTab NewLine NewCell HLine

%type <line> Lines
%type <cell> Line
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

Lines : Line { $$ = newLine($1, NULL); }
      | Line NewLine { $$ = newLine($1, NULL); }
      | Line NewLine Lines { $$ = newLine($1, $3); }
      | HLine { $$ = NULL; }
      | HLine NewLine { $$ = NULL; }
      | HLine Lines { $$ = $2; }
      | HLine NewLine Lines { $$ = $3; }
      ;

Line : String {
           CellContent cc = { .string = $1 };
           $$ = newCell(STRING, cc, NULL);
       }
     | Number {
           CellContent cc = { .number = $1 };
           $$ = newCell(NUMBER, cc, NULL);
       }
     | String NewCell Line {
           CellContent cc = { .string = $1 };
           $$ = newCell(STRING, cc, $3);
       }
     | Number NewCell Line {
           CellContent cc = { .number = $1 };
           $$ = newCell(NUMBER, cc, $3);
       }
     ;

Garbage : String { $$ = NULL; }
        | Number { $$ = NULL; }
        | NewLine { $$ = NULL; }
        | NewCell { $$ = NULL; }
        | OpenBeginTab { $$ = NULL; }
        | CloseBeginTab { $$ = NULL; }
        | EndTab { $$ = NULL; }
        | HLine { $$ = NULL; }
        | Garbage String { $$ = NULL; }
        | Garbage Number { $$ = NULL; }
        | Garbage NewLine { $$ = NULL; }
        | Garbage NewCell { $$ = NULL; }
        | Garbage OpenBeginTab { $$ = NULL; }
        | Garbage CloseBeginTab { $$ = NULL; }
        | Garbage EndTab { $$ = NULL; }
        | Garbage HLine { $$ = NULL; }
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



