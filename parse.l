%{
#include "ast.h"
#include "parse.tab.h"
#include <string.h>

int colno = 1;
%}

%option noyywrap
%option debug

%%
\n                  { colno = 1; yylineno++; /* Ignore Newline */ }
"//"[^\n]*          { ; }

[\t\r ]+          { colno += yyleng; /* Ignore whitespace */ }

"const"             { colno += yyleng; return CONST; }
"="                 { colno += yyleng; return ASSIGN; }
"-"                 { colno += yyleng; return DASH; }
"/"                 { colno += yyleng; return SLASH; }
"&"                 { colno += yyleng; return AND; }
"!"                 { colno += yyleng; return NOT; }
"|"                 { colno += yyleng; return ALT; }
"*"                 { colno += yyleng; return STAR; }
"+"                 { colno += yyleng; return PLUS; }
"?"                 { colno += yyleng; return QUESTION; }
"$"					{ colno += yyleng; return DOLLAR; }
"{"                 { colno += yyleng; return LBRACE; }
"}"                 { colno += yyleng; return RBRACE; }
"("                 { colno += yyleng; return LPAREN; }
")"                 { colno += yyleng; return RPAREN; }

"^"                 { colno += yyleng; return CARET; }
"."                 { colno += yyleng; return DOT; }

"%x[0-9]+;"         { colno += yyleng; yylval.str = strdup(yytext); return ESCAPED_UNICODE; }


[a-zA-Z_][a-zA-Z0-9_]* { colno += yyleng; yylval.str = strdup(yytext); return ID; }
"["("^"?)([^\]]|\\.|-)*"]"    { colno += yyleng; yylval.str = strdup(yytext); return CHAR_RANGE; }

\"(\\.|[^"\\])*?\"  { colno += yyleng; yylval.str = strdup(yytext); return LITERAL; }


.  { fprintf(stderr, "Unexpected token at line %d, column %d: '%s'\n", yylineno, colno, yytext); exit(1); }

%%

