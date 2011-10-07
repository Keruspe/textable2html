tmp_sources = latex-lex.c latex-yacc.c
sources = $(tmp_sources) latextohtml.c
objects = $(sources:.c=.o)
bin     = latextohtml

LEX     = flex
YACC    = bison -y

D_CFLAGS  = -g -ggdb3 -Wall -Wextra -Wno-unused-function -pedantic -std=gnu99 -O3 -march=native
D_LDFLAGS = -Wl,-O3 -Wl,--as-needed
D_YFLAGS  = -d

CFLAGS  := $(D_CFLAGS) $(CFLAGS)
LDFLAGS := $(D_LDFLAGS) $(LDFLAGS)
YFLAGS  := $(D_YFLAGS) $(YFLAGS)

all: $(bin)

$(bin): $(objects)
	$(LINK.c) $^ $(LOADLIBES) $(LDLIBS) -o $@ -lfl

latex-yacc.o: latex-yacc.y
latex-lex.o: latex-lex.l latex-yacc.c y.tab.h

clean:
	$(RM) $(tmp_sources) $(objects) $(bin) y.tab.h

.PHONY: all clean
