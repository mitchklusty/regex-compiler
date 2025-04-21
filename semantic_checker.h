// semantic_checker.h
#ifndef SEMANTIC_CHECKER_H
#define SEMANTIC_CHECKER_H

#include "ast.h"
#include "symbol_table.h"
#include <stdbool.h>

// Function prototypes
bool check_semantics(ASTNode* root, SymbolTable* table);
bool check_node(ASTNode* node, SymbolTable* table);
bool check_escaped_unicode(const char* str);

#endif // SEMANTIC_CHECKER_H