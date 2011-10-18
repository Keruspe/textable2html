#ifndef __TYPES_H__
#define __TYPES_H__

#include <stdbool.h>

/* Typedefs to make it handier */
typedef struct _Cell Cell;
typedef struct _Line Line;
typedef struct _Table Table;

/* Different kind of format available */
typedef enum {
    CENTER = 'c',
    LEFT = 'l',
    RIGHT = 'r',
    SEPARATOR = '|'
} FormatKind;

/* Different kind of cells available */
typedef enum {
    NUMBER,
    INTEGER,
    STRING
} CellKind;

/* The content of a cell */
typedef union {
    char *string;
    int   integer;
    float number;
} CellContent;

/* A cell, with its kind, content, size and special format (for multicol), pointing to the next one */
struct _Cell {
    CellKind kind;
    CellContent content;
    unsigned int size;
    FormatKind special_format;
    Cell *next;
};

/* A line containing cells and pointing to the next one */
struct _Line {
    Cell *cells;
    Line *next;
};

/* A table containing its format, lines, whether we have to draw the borders, the number of columns and its caption */
struct _Table {
    char *format;
    Line *lines;
    bool borders;
    unsigned int nb_cols;
    char *caption;
};

#endif /*__TYPES_H__*/

