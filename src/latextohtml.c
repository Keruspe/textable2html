#include "construct.h"

#include <stdio.h>

const char *input_file;
bool no_string = true;
bool integers_only = true;
int nb_line = 1;

int yylex_destroy ();
int yyparse ();
void yyset_in (FILE *in_str);

static void
print_header (FILE *out, bool borders, const char *format)
{
    fprintf (out,
             "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
             "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.1//EN\" \"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd\">\n"
             "<html version=\"-//W3C//DTD XHTML 1.1//EN\"\n"
             "      xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"en\"\n"
             "      xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n"
             "      xsi:schemaLocation=\"http://www.w3.org/1999/xhtml\n"
             "                          http://www.w3.org/MarkUp/SCHEMA/xhtml11.xsd\"\n"
             ">\n"
             "    <head>\n"
             "        <meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\" />\n"
             "        <title>Table</title>\n"
             "        <style type=\"text/css\">\n"
             "            td { padding: 10px; ");
    if (borders)
        fprintf (out,
                 "border: solid 1px; }\n"
                 "            table { border-collapse: collapse; ");
    fprintf (out, "}\n");
    unsigned int j = 0;
    for (unsigned int i = 0; i < strlen (format); ++i)
    {
        const char *align;
        switch (format[i]) {
        case CENTER:
            align = "center;";
            break;
        case LEFT:
            align = "left;  ";
            break;
        case RIGHT:
            align = "right; ";
            break;
        default:
            continue;
        }
        fprintf (out, "            .col%u { text-align: %s }\n", j++, align);
    }
    if (no_string) /* For the total col */
        fprintf (out, "            .col%u { text-align: center; }\n", j);
    fprintf (out,
             "            .center { text-align: center; }\n"
             "            .left   { text-align: left;   }\n"
             "            .right  { text-align: right;  }\n"
             "        </style>\n"
             "    </head>\n"
             "    <body>\n"
             "        <div>\n"
             "            <table>\n");
}

static void
print_caption (FILE *out, const char *caption)
{
    if (caption)
        fprintf (out, "                <caption>%s</caption>\n", caption);
}

static void
print_cell_header (FILE *out, unsigned int size, FormatKind format, unsigned int nb_col)
{
    fprintf (out, "                    <td class=\"col%d", nb_col);
    if (size > 1)
    {
        const char *additional_format;
        switch (format)
        {
        case CENTER:
            additional_format = "center";
            break;
        case LEFT:
            additional_format = "left";
            break;
        case RIGHT:
            additional_format = "right";
            break;
        case SEPARATOR:
            /* We should never get there */
            break;
        }
        fprintf (out, " %s\" colspan=\"%d", additional_format, size);
    }
    fprintf (out, "\">");
}

static void
print_cell_content (FILE *out, Cell *cell, const char *default_number_format)
{
    const char *number_format = (no_string) ? default_number_format : (cell->kind == INTEGER) ? "%d" : "%f";
    switch (cell->kind)
    {
    case NUMBER:
        fprintf (out, number_format, cell->content.number);
        break;
    case INTEGER:
        fprintf (out, number_format, cell->content.integer);
        break;
    case STRING:
        fprintf (out, "%s", cell->content.string);
    }
}

static void
print_cell_footer (FILE *out)
{
    fprintf (out, "</td>\n");
}

static unsigned int
print_cell (FILE *out, Cell *cell, unsigned int nb_col, const char *default_number_format)
{
    print_cell_header (out, cell->size, cell->special_format, nb_col);
    print_cell_content (out, cell, default_number_format);
    print_cell_footer (out);
    return cell->size - 1;
}

static void
print_empty_cells (FILE *out, unsigned int nb_col, unsigned int max)
{
    for (; nb_col < max; ++nb_col)
        fprintf (out, "                    <td class=\"col%d\"></td>\n", nb_col);
}

static void
print_line (FILE *out, Cell *cell, unsigned int nb_cols, const char *default_number_format, Cell *total)
{
    fprintf (out, "                <tr>\n");
    unsigned int i;
    int   isum = 0;
    float fsum = 0;
    for (i = 0; cell && i < nb_cols; ++i, cell = cell->next)
    {
        if (no_string)
        {
            switch (cell->kind)
            {
            case INTEGER:
                if (integers_only)
                {
                    isum += cell->content.integer;
                    if (total)
                        total->content.integer += cell->content.integer;
                    break;
                }
                /* Convert cell value as number and let the NUMBER case handle it so don't break */
                cell->content.number = (float) cell->content.integer;
                cell->kind = NUMBER;
            case NUMBER:
                fsum += cell->content.number;
                if (total)
                    total->content.number += cell->content.number;
                break;
            default:
                /* We should never get there */
                break;
            }
            if (total)
                total = total->next;
        }
        i += print_cell (out, cell, i, default_number_format);
    }
    print_empty_cells (out, i, nb_cols);
    if (no_string)
    {
        if (integers_only)
            fprintf (out, "                    <td class=\"col%d\">%d</td>\n", i, isum);
        else
            fprintf (out, "                    <td class=\"col%d\">%f</td>\n", i, fsum);
    }
    fprintf (out, "                </tr>\n");
}

static void
print_lines (FILE *out, Line *lines, unsigned int nb_cols)
{
    Cell *totals = NULL;
    if (no_string)
    {
        /* Allocate cells to store the columns totals if there is no string */
        if (integers_only)
        {
            for (unsigned int i = 0; i < nb_cols; ++i)
                totals = new_integer_cell (0, 1, '\0', totals);
        }
        else
        {
            for (unsigned int i = 0; i < nb_cols; ++i)
                totals = new_number_cell (0, 1, '\0', totals);
        }
    }
    const char *default_number_format = (integers_only) ? "%d" : "%f";
    for (; lines; lines = lines->next)
        print_line (out, lines->cells, nb_cols, default_number_format, totals);
    if (no_string)
        print_line (out, totals, nb_cols, default_number_format, NULL);
}

static void
print_footer (FILE *out)
{
    fprintf (out,
             "            </table>\n"
             "        </div>\n"
             "    </body>\n"
             "</html>\n");
}

void
htmlize (Table *table)
{
    char *output_file = (char *) malloc ((strlen (input_file) + 2) * sizeof (char));
    strcpy (output_file, input_file);
    strcpy (output_file + strlen (input_file) - 3, "html");
    FILE *out = fopen (output_file, "w");
    if (!out)
        out = stdout;
    free (output_file);
    print_header (out, table->borders, table->format);
    print_caption (out, table->caption);
    print_lines (out, table->lines, table->nb_cols);
    print_footer (out);
    free_table (table);
    fclose (out);
}

/* Basic error reporting */
void
yyerror(char *error)
{
    fprintf (stderr, "Error line %d: %s\n", nb_line, error);
    yylex_destroy ();
    exit (1);
}

int
main(int argc, char *argv[])
{
    /* We need an input file */
    if (argc != 2) {
        fprintf (stderr, "usage: %s <file>\n", argv[0]);
        yyerror ("bad invocation");
    }
    /* Store the input file name to generate the output one */
    input_file = argv[1];
    FILE *in = fopen (input_file, "r");
    /* lex will fall back to stdin if file doesn't exist */
    yyset_in (in);
    yyparse ();
    yylex_destroy ();
    fclose (in);
    return 0;
}

