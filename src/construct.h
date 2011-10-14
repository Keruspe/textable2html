#ifndef __CONSTRUCT_H__
#define __CONSTRUCT_H__

#include "types.h"

#include <stdlib.h>
#include <string.h>

Table *new_table (char *format,
                  Line *lines,
                  char *caption);

Line *new_line (Cell *cells,
                Line *next);

Cell *new_cell (CellKind     kind,
                CellContent  content,
                unsigned int size,
                FormatKind   format,
                Cell        *next);

char *make_caps (char *string);

char *surround_with (char       *string,
                     const char *tag);

char *append (char *string,
              char *other);

char *append_const (char       *string,
                    const char *other);

void free_table (Table *table);

#endif /*__CONSTRUCT_H__*/

