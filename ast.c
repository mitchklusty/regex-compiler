// ast.c
#include "ast.h"
#include <stdio.h>
#include <string.h>

ASTNode* create_const_def_node(char* name, ASTNode* regex, int line, int column) {
    ASTNode* node = (ASTNode*)malloc(sizeof(ASTNode));
    node->type = NODE_CONST_DEF;
    node->data.const_def.name = strdup(name);
    node->data.const_def.regex = regex;
    node->line = line;
    node->column = column;
    return node;
}

ASTNode* create_binary_op_node(NodeType type, ASTNode* left, ASTNode* right, int line, int column) {
    ASTNode* node = (ASTNode*)malloc(sizeof(ASTNode));
    node->type = type;
    node->data.binary_op.left = left;
    node->data.binary_op.right = right;
    node->line = line;
    node->column = column;
    return node;
}

ASTNode* create_unary_op_node(NodeType type, ASTNode* expr, int line, int column) {
    ASTNode* node = (ASTNode*)malloc(sizeof(ASTNode));
    node->type = type;
    node->data.unary_op.expr = expr;
    node->line = line;
    node->column = column;
    return node;
}

ASTNode* create_repetition_node(ASTNode* expr, RepetitionType rep_type, int line, int column) {
    ASTNode* node = (ASTNode*)malloc(sizeof(ASTNode));
    node->type = NODE_REPETITION;
    node->data.repetition.expr = expr;
    node->data.repetition.rep_type = rep_type;
    node->line = line;
    node->column = column;
    return node;
}

ASTNode* create_literal_node(char* value, int line, int column) {
    ASTNode* node = (ASTNode*)malloc(sizeof(ASTNode));
    node->type = NODE_LITERAL;
    node->data.literal.value = strdup(value);
    node->line = line;
    node->column = column;
    return node;
}

ASTNode* create_wild_node(int line, int column) {
    ASTNode* node = (ASTNode*)malloc(sizeof(ASTNode));
    node->type = NODE_WILD;
    node->line = line;
    node->column = column;
    return node;
}

ASTNode* create_char_range_node(char* value, int line, int column) {
    ASTNode* node = (ASTNode*)malloc(sizeof(ASTNode));
    node->type = NODE_CHAR_RANGE;
    node->data.char_range.value = strdup(value);
    node->line = line;
    node->column = column;
    return node;
}

ASTNode* create_substitute_node(char* name, int line, int column) {
    ASTNode* node = (ASTNode*)malloc(sizeof(ASTNode));
    node->type = NODE_SUBSTITUTE;
    node->data.substitute.name = strdup(name);
    node->data.substitute.is_bound = false;  // Initially not bound
    node->line = line;
    node->column = column;
    return node;
}

void free_ast(ASTNode* node) {
    if (node == NULL) return;
    
    switch (node->type) {
        case NODE_CONST_DEF:
            free(node->data.const_def.name);
            free_ast(node->data.const_def.regex);
            break;
        case NODE_ROOT_REGEX:  // Add this case
            free_ast(node->data.unary_op.expr);  // Assuming it has a similar structure to unary_op
            break;
        case NODE_SEQUENCE:
        case NODE_ALTERNATIVE:
        case NODE_AND:
            free_ast(node->data.binary_op.left);
            free_ast(node->data.binary_op.right);
            break;
        case NODE_NOT:
            free_ast(node->data.unary_op.expr);
            break;
        case NODE_REPETITION:
            free_ast(node->data.repetition.expr);
            break;
        case NODE_LITERAL:
            free(node->data.literal.value);
            break;
        case NODE_CHAR_RANGE:
            free(node->data.char_range.value);
            break;
        case NODE_SUBSTITUTE:
            free(node->data.substitute.name);
            break;
        case NODE_WILD:
            // Nothing to free
            break;
        default:
            fprintf(stderr, "Warning: Unknown node type %d in free_ast\n", node->type);
            break;
    }
    
    free(node);
}