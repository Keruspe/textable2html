tmp_sources = src/latex-lex.c src/latex-yacc.c
sources = $(tmp_sources) src/construct.c src/latextohtml.c
objects = $(sources:.c=.o)
bin     = latextohtml

LEX     = flex
YACC    = bison -y

D_CFLAGS  = -g -ggdb3 -Wall -Wextra -Wno-unused-function -pedantic -std=gnu99 -O3 -march=native -I.. -I.
D_LDFLAGS = -Wl,-O3 -Wl,--as-needed
D_YFLAGS  = -d

CFLAGS  := $(D_CFLAGS) $(CFLAGS)
LDFLAGS := $(D_LDFLAGS) $(LDFLAGS)
YFLAGS  := $(D_YFLAGS) $(YFLAGS)

all: $(bin) samples

$(bin): $(objects)
	$(LINK.c) $^ $(LOADLIBES) $(LDLIBS) -o $@ -lfl

src/latex-yacc.o: src/latex-yacc.y
src/latex-lex.o: src/latex-lex.l src/latex-yacc.c y.tab.h

clean:
	$(RM) $(tmp_sources) $(objects) $(bin) y.tab.h sample/*.html

samples: sample/test.html sample/full_numbers.html

sample/%.html: sample/%.tex $(bin)
	./$(bin) $<

.PHONY: all clean
