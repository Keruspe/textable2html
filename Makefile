generated_sources = src/latex-lex.c src/latex-yacc.c
sources = $(generated_sources) src/construct.c src/latextohtml.c
objects = $(sources:.c=.o)
bin     = latextohtml

LEX  = flex
YACC = bison -y

D_CFLAGS  = -g -ggdb3 -Wall -Wextra -pedantic -std=gnu99 -O3 -march=native -I.. -I. -DYY_NO_INPUT
D_LDFLAGS = -Wl,-O3 -Wl,--as-needed
D_YFLAGS  = -d

CFLAGS  := $(D_CFLAGS)  $(CFLAGS)
LDFLAGS := $(D_LDFLAGS) $(LDFLAGS)
YFLAGS  := $(D_YFLAGS)  $(YFLAGS)

all: $(bin) samples

$(bin): $(objects)
	$(LINK.c) $^ $(LOADLIBES) $(LDLIBS) -o $@ -lfl

src/latex-yacc.o: src/latex-yacc.y
src/latex-lex.o: src/latex-lex.l src/latex-yacc.c y.tab.h

clean:
	$(RM) $(generated_sources) $(objects) $(bin) y.tab.h sample/*.html

samples: sample/test.html sample/full_numbers.html sample/example.html

sample/%.html: sample/%.tex $(bin)
	./$(bin) $<

valgrind-check: sample/test.tex sample/full_numbers.tex sample/example.tex $(bin)
	for i in $(filter-out $(bin), $^); do valgrind --leak-check=full --show-reachable=yes ./$(bin) $$i || break; done

.PHONY: all clean samples valgrind-check
