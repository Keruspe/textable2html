#ifndef __CONSTRUCT_H__
#define __CONSTRUCT_H__

#include "types.h"

#include <stdlib.h>
#include <string.h>

Table *new_table (char *format, Line *lines);
Line *new_line (Cell *cells, Line *next);
Cell *new_cell (CellKind kind, CellContent content, int size, FormatKind format, Cell *next);
void free_table (Table *table);

#endif /*__CONSTRUCT_H__*/

