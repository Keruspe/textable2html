#include "construct.h"

#include <stdio.h>

extern bool numbers_only;

Table *
new_table (char *format, Line *lines, char *caption)
{
    Table *table = (Table *) malloc (sizeof (Table));
    table->format = format;
    table->lines = lines;
    unsigned int nb_cell = 0, nb_separator = 0;
    for (unsigned int i = 0; i < strlen (format); ++i) {
        if (format[i] == SEPARATOR)
            ++nb_separator;
        else
            ++nb_cell;
    }
    table->borders = (nb_separator > (nb_cell / 2));
    table->nb_cell = nb_cell;
    table->caption = caption;
    return table;
}

Line *
new_line (Cell *cells, Line *next)
{
    Line *line = (Line *) malloc (sizeof (Line));
    line->cells = cells;
    line->next = next;
    return line;
}

Cell *
new_cell (CellKind kind, CellContent content, unsigned int size, FormatKind format, Cell *next)
{
    Cell *cell = (Cell *) malloc (sizeof (Cell));
    cell->kind = kind;
    cell->content = content;
    cell->size = size;
    cell->special_format = format;
    cell->next = next;
    if (kind != NUMBER)
        numbers_only = false;
    return cell;
}

char *
make_caps (char *string)
{
    for (unsigned int i = 0; i < strlen (string); ++i)
    {
        if (string[i] >= 'a' && string[i] <= 'z')
            string[i] += ('A' - 'a');
    }
    return string;
}

char *
surround_with (char *string, const char *tag)
{
    char *result = (char *) malloc ((strlen (string) + 2 * strlen (tag) + 6) * sizeof (char));
    sprintf (result, "<%s>%s</%s>", tag, string, tag);
    free (string);
    return result;
}

static char *
append_internal (char *string, char *other, bool other_needs_free)
{
    string = (char *) realloc (string, (strlen (string) + strlen (other) + 1) * sizeof (char));
    strcat (string, other);
    if (other_needs_free)
        free (other);
    return string;
}

char *
append (char *string, char *other)
{
    return append_internal (string, other, true);
}

char *
append_const (char *string, const char *other)
{
    return append_internal (string, (char *) other, false);
}

void
free_table (Table *table)
{
    free (table->format);
    Line *line = table->lines;
    while (line)
    {
        Line *next_line = line->next;
        Cell *cell = line->cells;
        while (cell)
        {
            Cell *next_cell = cell->next;
            switch (cell->kind)
            {
            case STRING:
                free (cell->content.string);
            case NUMBER:
                free (cell);
                break;
            }
            cell = next_cell;
        }
        free (line);
        line = next_line;
    }
    free (table->caption);
    free (table);
}

