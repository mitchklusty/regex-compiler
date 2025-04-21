#include <stdio.h>
#include <stdlib.h>
#include "ast.h"
#include "symbol_table.h"
#include "semantic_checker.h"

extern int yyparse();
extern FILE *yyin;
extern void yyrestart(FILE *input_file);  // Ensure Flex restarts correctly
extern ASTNode* ast_root;
extern SymbolTable* symbol_table;

int main(int argc, char **argv) {
    // Check command line arguments
    if (argc < 2) {
        fprintf(stderr, "Usage: %s input_file\n", argv[0]);
        return 1;
    }
    
    // Open input file
    FILE *input = fopen(argv[1], "r");
    if (!input) {
        fprintf(stderr, "Cannot open input file %s\n", argv[1]);
        return 1;
    }
    yyin = input;
    
    // Initialize compiler components
    init_compiler();
    
    // Parse the input
    if (yyparse() != 0) {
        fprintf(stderr, "Parsing failed\n");
        cleanup_compiler();
        fclose(input);
        return 1;
    }
    
    // Perform semantic checking
    if (ast_root != NULL) {
        if (!check_semantics(ast_root, symbol_table)) {
            fprintf(stderr, "Semantic errors found\n");
            cleanup_compiler();
            fclose(input);
            return 1;
        }
    }
    
    printf("Compilation successful\n");
    
    // Clean up
    cleanup_compiler();
    fclose(input);
    
    return 0;
}