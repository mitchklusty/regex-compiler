%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ast.h"
#include "symbol_table.h"
#include "semantic_checker.h"

extern int yylex();
extern char *yytext;
extern int yylineno;
extern int colno;  // Make sure this is declared in your lexer
extern int yyparse();
extern FILE *yyin;
extern void yyrestart(FILE *input_file);

void yyerror(const char *s);

// Root of the AST
ASTNode* ast_root = NULL;

// Symbol table
SymbolTable* symbol_table;

// Initialize everything
void init_compiler() {
    symbol_table = create_symbol_table(100);
}

// Clean up
void cleanup_compiler() {
    free_ast(ast_root);
    free_symbol_table(symbol_table);
}
%}


%union {
    char *str;
    int num;
    ASTNode *node;
    RepetitionType rep_type;
    RepetitionSequence rep_seq;
}


%token <str> CONST ASSIGN DASH SLASH AND NOT ALT STAR PLUS QUESTION DOLLAR LBRACE RBRACE LPAREN RPAREN CARET DOT ESCAPED_UNICODE CHAR_RANGE ID LITERAL

%type <node> System DefinitionList Definition RootRegex Regex Alt Seq Repeat AtomicExpr Term Literal Wild Range Substitute
%type <rep_type> RepeatOp
%type <rep_seq> RepeatSeq


%left ALT
%left AND
%left NOT

%left STAR PLUS QUESTION
%left LPAREN RPAREN
%left LITERAL

%%

System:
    DefinitionList SLASH RootRegex SLASH 
    {
        // Create system node containing all definitions and root regex
        ast_root = $3;
    }
    | /* empty */
    {
        ast_root = NULL;
    }
    ;

DefinitionList:
    Definition DefinitionList
    {
        // Definitions are stored in the symbol table, nothing to do here
    }
    | /* empty */
    {
        // Nothing to do
    }
    ;

Definition:
    CONST ID ASSIGN SLASH RootRegex SLASH 
    {
        ASTNode* def_node = create_const_def_node($2, $5, yylineno, colno);
        if (!add_symbol(symbol_table, $2, def_node)) {
            fprintf(stderr, "Error at line %d: Redefinition of constant '%s'\n", yylineno, $2);
            YYERROR;
        }
        $$ = def_node;
        free($2);
    }
    ;

RootRegex:
    Regex AND RootRegex 
    {
        $$ = create_binary_op_node(NODE_AND, $1, $3, yylineno, colno);
    }
    | NOT Regex 
    {
        $$ = create_unary_op_node(NODE_NOT, $2, yylineno, colno);
    }
    | Regex
    {
        $$ = $1;
    }
    ;

Regex:
    Alt 
    {
        $$ = $1;
    }
    ;

Alt:
    Seq 
    {
        $$ = $1;
    }
    | Seq ALT Alt
    {
        $$ = create_binary_op_node(NODE_ALTERNATIVE, $1, $3, yylineno, colno);
    }
    ;

Seq:
    Repeat 
    {
        $$ = $1;
    }
    | Repeat Seq
    {
        $$ = create_binary_op_node(NODE_SEQUENCE, $1, $2, yylineno, colno);
    }
    ;

Repeat:
    AtomicExpr RepeatSeq
    {
        ASTNode* node = $1;
        for (int i = 0; i < $2.count; i++) {
            node = create_repetition_node(node, $2.types[i], yylineno, colno);
        }
        $$ = node;
    }
    ;

AtomicExpr:
    Term
    {
        $$ = $1;
    }
    | LPAREN Regex RPAREN
    {
        $$ = $2;
    }
    ;

RepeatSeq:
    RepeatSeq RepeatOp
    {
        if ($1.count < MAX_REPEAT_OPS) {
            $$.types[$1.count] = $2;
            $$.count = $1.count + 1;
        } else {
            yyerror("Too many repetition operators");
        }
    }
    | /* empty */
    {
        $$.count = 0;
    }
    ;

RepeatOp:
    STAR    { $$ = REP_STAR; }
    | PLUS   { $$ = REP_PLUS; }
    | QUESTION { $$ = REP_QUESTION; }
    ;

// Repeat:
//     Term RepeatOp
//     {
//         $$ = create_repetition_node($1, $2, yylineno, colno);
//     }
//     | Term
//     {
//         $$ = $1;
//     }
//     | LPAREN Regex RPAREN RepeatOp
//     {
//         $$ = create_repetition_node($2, $4, yylineno, colno);
//     }
//     | LPAREN Regex RPAREN
//     {
//         $$ = $2;
//     }
//     ;

// RepeatOp:
//     STAR    { $$ = REP_STAR; }
//     | PLUS   { $$ = REP_PLUS; }
//     | QUESTION { $$ = REP_QUESTION; }
//     ;

Term:
    Literal
    {
        $$ = $1;
    }
    | Wild
    {
        $$ = $1;
    }
    | Range
    {
        $$ = $1;
    }
    | Substitute
    {
        $$ = $1;
    }
    ;

Literal:
    LITERAL
    {
        $$ = create_literal_node($1, yylineno, colno);
        free($1);
    }
    ;

Wild:
    DOT
    {
        $$ = create_wild_node(yylineno, colno);
    }
    ;

Range:
    CHAR_RANGE
    {
        $$ = create_char_range_node($1, yylineno, colno);
        free($1);
    }
    ;

Substitute:
    DOLLAR LBRACE ID RBRACE
    {
        $$ = create_substitute_node($3, yylineno, colno);
        free($3);
    }
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Syntax Error: %s at line %d near '%s'\n", s, yylineno, yytext);
    exit(1);
}

// int main(int argc, char **argv) {
//     // Check command line arguments
//     if (argc < 2) {
//         fprintf(stderr, "Usage: %s input_file\n", argv[0]);
//         return 1;
//     }
    
//     // Open input file
//     FILE *input = fopen(argv[1], "r");
//     if (!input) {
//         fprintf(stderr, "Cannot open input file %s\n", argv[1]);
//         return 1;
//     }
//     yyin = input;
    
//     // Initialize compiler components
//     init_compiler();
    
//     // Parse the input
//     if (yyparse() != 0) {
//         fprintf(stderr, "Parsing failed\n");
//         cleanup_compiler();
//         fclose(input);
//         return 1;
//     }
    
//     // Perform semantic checking
//     if (ast_root != NULL) {
//         if (!check_semantics(ast_root, symbol_table)) {
//             fprintf(stderr, "Semantic errors found\n");
//             cleanup_compiler();
//             fclose(input);
//             return 1;
//         }
//     }
    
//     printf("Compilation successful\n");
    
//     // Clean up
//     cleanup_compiler();
//     fclose(input);
    
//     return 0;
// }