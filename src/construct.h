#ifndef __CONSTRUCT_H__
#define __CONSTRUCT_H__

#include "types.h"

#include <stdlib.h>
#include <string.h>

/* Create a new table with the given format, containing the given lines and caption */
Table *new_table (char *format,
                  Line *lines,
                  char *caption);

/* Create a new line containing the given cells and pointing to the next one */
Line *new_line (Cell *cells,
                Line *next);

/* Create a new cell containing an integer */
Cell *new_integer_cell (int          value,
                        unsigned int size,
                        FormatKind   format,
                        Cell        *next);

/* Create a new cell containing a number */
Cell *new_number_cell (float        value,
                       unsigned int size,
                       FormatKind   format,
                       Cell        *next);

/* Create a new cell containing a string */
Cell *new_string_cell (char        *value,
                       unsigned int size,
                       FormatKind   format,
                       Cell        *next);

/* Convert a string to caps */
char *make_caps (char *string);

/* Surround a string with a tag */
char *surround_with (char       *string,
                     const char *tag);

/* Append other to string (and free other) */
char *append (char *string,
              char *other);

/* Append other to string */
char *append_const (char       *string,
                    const char *other);

/* Free memory */
void free_cells (Cell *cell);

/* Free memory */
void free_table (Table *table);

#endif /*__CONSTRUCT_H__*/

