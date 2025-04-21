// symbol_table.c
#include "symbol_table.h"
#include <string.h>

SymbolTable* create_symbol_table(int initial_capacity) {
    SymbolTable* table = (SymbolTable*)malloc(sizeof(SymbolTable));
    table->entries = (SymbolEntry*)malloc(sizeof(SymbolEntry) * initial_capacity);
    table->capacity = initial_capacity;
    table->size = 0;
    return table;
}

void free_symbol_table(SymbolTable* table) {
    if (table == NULL) return;
    
    // We don't free the definitions here as they're part of the AST
    for (int i = 0; i < table->size; i++) {
        free(table->entries[i].name);
    }
    
    free(table->entries);
    free(table);
}

bool add_symbol(SymbolTable* table, char* name, ASTNode* definition) {
    // Check if symbol already exists
    for (int i = 0; i < table->size; i++) {
        if (strcmp(table->entries[i].name, name) == 0) {
            return false;  // Symbol already exists
        }
    }
    
    // Resize if needed
    if (table->size >= table->capacity) {
        table->capacity *= 2;
        table->entries = (SymbolEntry*)realloc(table->entries, sizeof(SymbolEntry) * table->capacity);
    }
    
    // Add new symbol
    table->entries[table->size].name = strdup(name);
    table->entries[table->size].definition = definition;
    table->size++;
    
    return true;
}

ASTNode* lookup_symbol(SymbolTable* table, char* name) {
    for (int i = 0; i < table->size; i++) {
        if (strcmp(table->entries[i].name, name) == 0) {
            return table->entries[i].definition;
        }
    }
    return NULL;  // Symbol not found
}