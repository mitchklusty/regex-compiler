// symbol_table.h
#ifndef SYMBOL_TABLE_H
#define SYMBOL_TABLE_H

#include "ast.h"
#include <stdbool.h>

// Symbol table entry structure
typedef struct {
    char* name;
    ASTNode* definition;
} SymbolEntry;

// Symbol table structure
typedef struct {
    SymbolEntry* entries;
    int capacity;
    int size;
} SymbolTable;

// Function prototypes
SymbolTable* create_symbol_table(int initial_capacity);
void free_symbol_table(SymbolTable* table);
bool add_symbol(SymbolTable* table, char* name, ASTNode* definition);
ASTNode* lookup_symbol(SymbolTable* table, char* name);

#endif // SYMBOL_TABLE_H