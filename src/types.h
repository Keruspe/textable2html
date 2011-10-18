#ifndef __TYPES_H__
#define __TYPES_H__

#include <stdbool.h>

typedef struct _Cell Cell;
typedef struct _Line Line;
typedef struct _Table Table;

typedef enum {
    CENTER = 'c',
    LEFT = 'l',
    RIGHT = 'r',
    SEPARATOR = '|'
} FormatKind;

typedef enum {
    NUMBER,
    INTEGER,
    STRING
} CellKind;

typedef union {
    char *string;
    int   integer;
    float number;
} CellContent;

struct _Cell {
    CellKind kind;
    CellContent content;
    unsigned int size;
    FormatKind special_format;
    Cell *next;
};

struct _Line {
    Cell *cells;
    Line *next;
};

struct _Table {
    char *format;
    Line *lines;
    bool borders;
    unsigned int nb_cell;
    char *caption;
};

#endif /*__TYPES_H__*/

