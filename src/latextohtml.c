#include "latextohtml.h"

#include <stdio.h>

const char *input_file;
bool numbers_only = true;

extern FILE * yyin;

extern int yylex_destroy ();
extern int yyparse ();

void
htmlize (Table *table)
{
    char *output_file = (char *) malloc ((strlen (input_file) + 2) * sizeof (char));
    sprintf (output_file, "%s", input_file);
    memcpy (output_file + strlen (input_file) - 3, "html", 5);
    FILE *out = fopen (output_file, "w");
    if (!out)
        out = stdout;
    free (output_file);
    fprintf (out,
            "<!DOCTYPE html>\n"
            "<html>\n"
            "    <head>\n"
            "        <title>Table</title>\n"
            "        <style>\n"
            "            td { padding: 10px; ");
    if (table->borders)
        fprintf (out,
                "border: solid 1px; }\n"
                "            table { border-collapse: collapse; ");
    fprintf (out, "}\n");
    for (unsigned int i = 0, j = 0; i < strlen (table->format); ++i) {
        char *align;
        switch (table->format[i]) {
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
        fprintf (out,
                "            .col%u { text-align: %s }\n", j++, align);
    }
    fprintf (out,
            "            .center { text-align: center; }\n"
            "            .left { text-align: left; }\n"
            "            .right { text-align: right; }\n"
            "        </style>\n"
            "    </head>\n"
            "    <body>\n");
    Line *line = table->lines;
    Cell *totals = NULL;
    if (numbers_only) {
        for (unsigned int i = 0; i <= table->nb_cell; ++i) {
            CellContent content = { .number = 0 };
            totals = new_cell (NUMBER, content, 1, '\0', totals);
        }
    }
    fprintf (out,
            "        <table>\n");
    while (line) {
        fprintf (out,
                "            <tr>\n");
        Cell *cell = line->cells;
        Cell *current = totals;
        unsigned int i;
        float sum = 0;
        for (i = 0; cell && i < table->nb_cell; ++i) {
            fprintf (out,
                    "                <td class=\"col%d", i);
            if (cell->size > 1) {
                char *format;
                switch (cell->special_format) {
                case CENTER:
                    format = "center";
                    break;
                case LEFT:
                    format = "left";
                    break;
                case RIGHT:
                    format = "right";
                    break;
                case SEPARATOR:
                    /* We should never get there */
                    break;
                }
                fprintf (out,
                        " %s\" colspan=\"%d", format, cell->size);
                i += (cell->size - 1);
            }
            fprintf (out,
                    "\">");
            switch (cell->kind) {
            case NUMBER:
                fprintf (out,
                        "%f", cell->content.number);
                break;
            case STRING:
                fprintf (out,
                        "%s", cell->content.string);
            }
            fprintf (out,
                    "</td>\n");
            if (numbers_only) {
                sum += cell->content.number;
                current->content.number += cell->content.number;
                current = current->next;
            }
            cell = cell->next;
        }
        for (; i < table->nb_cell; ++i) {
            if (numbers_only)
                current = current->next;
            fprintf (out,
                    "                <td class=\"col%d\"></td>\n", i);
        }
        if (numbers_only) {
            current->content.number += sum;
            fprintf (out,
                    "                <td class=\"col%d\">%f</td>\n", i, sum);
        }
        fprintf (out,
                "            </tr>\n");
        line = line->next;
    }
    if (numbers_only) {
        fprintf (out,
                "            <tr>\n");
        for (unsigned int i = 0; totals; ++i) {
            fprintf (out,
                    "                <td class=\"col%d\">%f</td>\n", i, totals->content.number);
            Cell *next = totals->next;
            free (totals);
            totals = next;
        }
        fprintf (out,
                "            </tr>\n");
    }
    fprintf (out,
            "        </table>\n"
            "    </body>\n"
            "</html>\n");
    fclose (out);
}

void
yyerror(char *error)
{
    fprintf (stderr, "Error : %s\n", error);
    yylex_destroy ();
    exit (1);
}

int
main(int argc, char *argv[])
{
    if (argc != 2) {
        fprintf (stderr, "usage: %s <file>\n", argv[0]);
        yyerror ("bad invocation");
    }
    input_file = argv[1];
    yyin = fopen (input_file, "r");
    yyparse ();
    yylex_destroy ();
    fclose (yyin);
    return 0;
}

