#include "construct.h"

extern bool numbers_only;

Table *
new_table (char *format, Line *lines, char *caption)
{
    Table *t = (Table *) malloc (sizeof (Table));
    t->format = format;
    t->lines = lines;
    unsigned int nb_cell = 0, nb_sep = 0;
    for (unsigned int i = 0; i < strlen (format); ++i) {
        if (format[i] == SEPARATOR)
            ++nb_sep;
        else
            ++nb_cell;
    }
    t->borders = (nb_sep > (nb_cell / 2));
    t->nb_cell = nb_cell;
    t->caption = caption;
    return t;
}

Line *
new_line (Cell *cells, Line *next)
{
    Line *l = (Line *) malloc (sizeof (Line));
    l->cells = cells;
    l->next = next;
    return l;
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

