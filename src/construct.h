#ifndef __CONSTRUCT_H__
#define __CONSTRUCT_H__

#include "types.h"

#include <stdlib.h>
#include <string.h>

Table *new_table (char *format, Line *lines, char *caption, bool caption_on_top);
Line *new_line (Cell *cells, Line *next);
Cell *new_cell (CellKind kind, CellContent content, unsigned int size, FormatKind format, Cell *next);
char *make_caps (char *string);
void free_table (Table *table);

#endif /*__CONSTRUCT_H__*/

