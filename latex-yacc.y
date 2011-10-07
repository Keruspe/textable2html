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

    const char *input_file;
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
        int size;
        struct Cell *next;
    } Cell;

    typedef struct Line {
        Cell *cells;
        struct Line *next;
    } Line;

    typedef enum {
        CENTER = 'c',
        LEFT = 'l',
        RIGHT = 'r',
        SEPARATOR = '|'
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
            if (format[i] == SEPARATOR)
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

    Cell *newCell(CellKind kind, CellContent content, int size, Cell *next) {
        Cell *c = (Cell *) malloc(sizeof(Cell));
        c->kind = kind;
        c->content = content;
        c->size = size;
        c->next = next;
        if (kind != NUMBER)
            numbers_only = false;
        return c;
    }

    void printTable(Table *t) {
        char *output_file = (char *) malloc((strlen(input_file) + 2) * sizeof(char));
        sprintf(output_file, "%s", input_file);
        memcpy(output_file + strlen(input_file) - 3, "html", 5);
        FILE *out = fopen(output_file, "w");
        if (!out)
            out = stdout;
        free(output_file);
        fprintf(out, "<!DOCTYPE html>\n<html>\n    <head>\n        <title>Table</title>\n        <style>\n            td { padding: 10px; ");
        if (t->borders)
            fprintf(out, "border: solid 1px; }\n            table { border-collapse: collapse; ");
        fprintf(out, "}\n");
        for (unsigned int i = 0, j = 0; i < strlen(t->format); ++i) {
            char *align;
            switch (t->format[i]) {
            case SEPARATOR:
                continue;
            case CENTER:
                align = "center";
                break;
            case LEFT:
                align = "left";
                break;
            case RIGHT:
                align = "right";
                break;
            }
            fprintf(out, "            .col%u { text-align: %s }\n", j++, align);
        }
        fprintf(out, "        </style>\n    </head>\n    <body>\n");
        Line *l = t->lines;
        Cell *total = NULL;
        if (numbers_only) {
            for (int i = 0; i <= t->nb_cell; ++i) {
                CellContent cc = { .number = 0 };
                total = newCell(NUMBER, cc, 1, total);
            }
        }
        fprintf(out, "        <table>\n");
        while (l) {
            fprintf(out, "            <tr>\n");
            Cell *cell = l->cells;
            Cell *current = total;
            int i;
            float sum = 0;
            for (i = 0; cell && i < t->nb_cell; ++i) {
                fprintf(out, "                <td class=\"col%d\"", i);
                if (cell->size > 1) {
                    fprintf(out, " colspan=\"%d\"", cell->size);
                    i += (cell->size - 1);
                }
                fprintf(out, ">");
                switch (cell->kind) {
                case NUMBER:
                    fprintf(out, "%f", cell->content.number);
                    break;
                case STRING:
                    fprintf(out, "%s", cell->content.string);
                }
                fprintf(out, "</td>\n");
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
                fprintf(out, "                <td class=\"col%d\"></td>\n", i);
            }
            if (numbers_only) {
                current->content.number += sum;
                fprintf(out, "                <td class=\"col%d\">%f</td>\n", i, sum);
            }
            fprintf(out, "            </tr>\n");
            l = l->next;
        }
        if (numbers_only) {
            fprintf(out, "            <tr>\n");
            for (int i = 0; total; ++i) {
                fprintf(out, "                <td class=\"col%d\">%f</td>\n", i, total->content.number);
                Cell *tmp = total->next;
                free(total);
                total = tmp;
            }
            fprintf(out, "            </tr>\n");
        }
        fprintf(out, "        </table>\n    </body>\n</html>\n");
        fclose(out);
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
%token BeginTab Open Close EndTab NewLine NewCell HLine MultiColumn

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

Table : BeginTab Open Format Close Lines EndTab { $$ = newTable($3, $5); }
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
           $$ = newCell(STRING, cc, 1, NULL);
       }
     | String NewCell Line {
           CellContent cc = { .string = $1 };
           $$ = newCell(STRING, cc, 1, $3);
       }
     | Number {
           CellContent cc = { .number = $1 };
           $$ = newCell(NUMBER, cc, 1, NULL);
       }
     | Number NewCell Line {
           CellContent cc = { .number = $1 };
           $$ = newCell(NUMBER, cc, 1, $3);
       }
       /* TODO: handle format for multi-cell */
     | MultiColumn Open Number Close Open Format Close Open String Close {
           CellContent cc = { .string = $9 };
           $$ = newCell(STRING, cc, $3, NULL);
       }
     | MultiColumn Open Number Close Open Format Close Open String Close NewCell Line {
           CellContent cc = { .string = $9 };
           $$ = newCell(STRING, cc, $3, $12);
       }
     | MultiColumn Open Number Close Open Format Close Open Number Close {
           CellContent cc = { .number = $9 };
           $$ = newCell(NUMBER, cc, $3, NULL);
       }
     | MultiColumn Open Number Close Open Format Close Open Number Close NewCell Line {
           CellContent cc = { .number = $9 };
           $$ = newCell(NUMBER, cc, $3, $12);
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
        | Garbage Open { $$ = NULL; }
        | Garbage Close { $$ = NULL; }
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
    input_file = argv[1];
    yyin = fopen(input_file, "r");
    yyparse();
    yylex_destroy();
    fclose (yyin);
    return 0;
}



