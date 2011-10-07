#ifndef __TYPES_H__
#define __TYPES_H__

#include <stdbool.h>

typedef enum {
    CENTER = 'c',
    LEFT = 'l',
    RIGHT = 'r',
    SEPARATOR = '|'
} FormatKind;

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
    FormatKind special_format;
    struct Cell *next;
} Cell;

typedef struct Line {
    Cell *cells;
    struct Line *next;
} Line;

typedef struct Table {
    char *format;
    Line *lines;
    bool borders;
    int nb_cell;
} Table;

#endif /*__TYPES_H__*/

