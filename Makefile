CC=gcc
CFLAGS=-Wall -g

all: parse

parse: lex.yy.c parse.tab.c ast.c symbol_table.c semantic_checker.c main.c 
	$(CC) $(CFLAGS) -o parse lex.yy.c parse.tab.c ast.c symbol_table.c semantic_checker.c main.c 

lex.yy.c: parse.l parse.tab.h
	flex parse.l

parse.tab.c parse.tab.h: parse.y
	bison -d parse.y

ast.c: ast.h
	$(CC) $(CFLAGS) -c ast.c

symbol_table.c: symbol_table.h
	$(CC) $(CFLAGS) -c symbol_table.c

semantic_checker.c: semantic_checker.h
	$(CC) $(CFLAGS) -c semantic_checker.c

test: parse
	@echo "Running shell test suite..."
	@chmod +x test.sh
	@./test.sh

clean:
	rm -f regex_compiler lex.yy.c parse.tab.c parse.tab.h *.o