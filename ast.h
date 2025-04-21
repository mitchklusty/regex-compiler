// ast.h
#ifndef AST_H
#define AST_H

#include <stdlib.h>
#include <stdbool.h>

// Node types for the AST
typedef enum {
    NODE_CONST_DEF,     // Constant definition
    NODE_ROOT_REGEX,    // Root level regex
    NODE_SEQUENCE,      // Sequence of regex expressions
    NODE_ALTERNATIVE,   // Alternative (|) operator
    NODE_REPETITION,    // Repetition (*, +, ?) operators
    NODE_NOT,           // Negation (!) operator
    NODE_AND,           // And (&) operator
    NODE_LITERAL,       // String literal
    NODE_WILD,          // Wildcard (.)
    NODE_CHAR_RANGE,    // Character range [...]
    NODE_SUBSTITUTE,    // Variable substitution ${...}
} NodeType;

// Repetition types
typedef enum {
    REP_NONE,
    REP_STAR,   // *
    REP_PLUS,   // +
    REP_QUESTION // ?
} RepetitionType;

#define MAX_REPEAT_OPS 10  // Maximum number of repetition operators in sequence
typedef struct {
    int count;
    RepetitionType types[MAX_REPEAT_OPS];
} RepetitionSequence;

// AST node structure
typedef struct ASTNode {
    NodeType type;
    union {
        struct {
            char* name;
            struct ASTNode* regex;
        } const_def;

        struct {
            struct ASTNode* left;
            struct ASTNode* right;
        } binary_op;

        struct {
            struct ASTNode* expr;
        } unary_op;

        struct {
            struct ASTNode* expr;
            RepetitionType rep_type;
        } repetition;

        struct {
            char* value;
        } literal;

        struct {
            char* value;
        } char_range;

        struct {
            char* name;
            bool is_bound;  // For semantic checking
        } substitute;
    } data;
    
    int line;
    int column;
} ASTNode;

// Function prototypes
ASTNode* create_const_def_node(char* name, ASTNode* regex, int line, int column);
ASTNode* create_binary_op_node(NodeType type, ASTNode* left, ASTNode* right, int line, int column);
ASTNode* create_unary_op_node(NodeType type, ASTNode* expr, int line, int column);
ASTNode* create_repetition_node(ASTNode* expr, RepetitionType rep_type, int line, int column);
ASTNode* create_literal_node(char* value, int line, int column);
ASTNode* create_wild_node(int line, int column);
ASTNode* create_char_range_node(char* value, int line, int column);
ASTNode* create_substitute_node(char* name, int line, int column);

void free_ast(ASTNode* node);

#endif // AST_H