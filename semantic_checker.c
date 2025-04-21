// semantic_checker.c
#include "semantic_checker.h"
#include <stdio.h>
#include <string.h>
#include <ctype.h>

#define UNICODE_MAX 0x10FFFF  // Maximum Unicode code point

bool check_semantics(ASTNode* root, SymbolTable* table) {
    if (root == NULL) return true;
    return check_node(root, table);
}

bool check_node(ASTNode* node, SymbolTable* table) {
    if (node == NULL) return true;
    
    bool valid = true;
    
    switch (node->type) {
        case NODE_CONST_DEF:
            // Check the regex part of the definition
            valid = check_node(node->data.const_def.regex, table);
            break;
            
        case NODE_SEQUENCE:
        case NODE_ALTERNATIVE:
        case NODE_AND:
            valid = check_node(node->data.binary_op.left, table) && 
                   check_node(node->data.binary_op.right, table);
            break;
            
        case NODE_NOT:
            valid = check_node(node->data.unary_op.expr, table);
            break;
            
        case NODE_REPETITION:
            valid = check_node(node->data.repetition.expr, table);
            break;
            
        case NODE_LITERAL:
            // Check for Unicode escapes in string literals
            valid = check_escaped_unicode(node->data.literal.value);
            break;
            
        case NODE_CHAR_RANGE:
            // Check for Unicode escapes in character ranges
            valid = check_escaped_unicode(node->data.char_range.value);
            break;
            
        case NODE_SUBSTITUTE:
            // Check if the substituted name exists in symbol table
            if (lookup_symbol(table, node->data.substitute.name) == NULL) {
                fprintf(stderr, "Error at line %d, column %d: Undefined name '%s' in substitution\n", 
                        node->line, node->column, node->data.substitute.name);
                valid = false;
            } else {
                node->data.substitute.is_bound = true;
            }
            break;
            
        case NODE_WILD:
            // Nothing to check for wildcards
            break;
    }
    
    return valid;
}

bool check_escaped_unicode(const char* str) {
    // Check for %x...; patterns
    const char* ptr = str;
    while ((ptr = strstr(ptr, "%x")) != NULL) {
        ptr += 2;  // Skip the "%x"
        
        char* end;
        long codepoint = strtol(ptr, &end, 16);
        
        // Check if there's a valid number followed by semicolon
        if (end == ptr || *end != ';' || codepoint < 0 || codepoint > UNICODE_MAX) {
            fprintf(stderr, "Error: Invalid Unicode escape sequence '%s'\n", str);
            return false;
        }
        
        // Move past this escape sequence
        ptr = end + 1;
    }
    
    return true;
}