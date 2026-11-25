%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "table.h"
#include "expr.h"
#include "stmt.h"

extern FILE *yyin;
extern int yylex(void);
void yyerror(const char*);

struct stmt * parser_result = 0;
%}

%token PLUS MINUS TIMES DIVIDE MODULE
       LESS GREATER EQUAL AND OR NOT
       LBRACE RBRACE SEMI
       SET IF IFELSE THEN ELSE REPEATN REPEATIF PRINT PRINTNL

/********* Types of pseudovariables $$, $1,... *********/
%union {
  struct stmt * stmt;
  struct expr * expr;
  char* str;
  int numb;
};

%type <stmt> LS S
%type <expr> EXPR VARNAME
%token <numb> NUMBER
%token <str> STRING VNAME

/************* Precedence of operations *************/
%left AND OR
%nonassoc LESS GREATER EQUAL
%left PLUS MINUS
%left TIMES DIVIDE MODULE
%precedence NOT

%%
P: LS YYEOF { parser_result = $1; }
LS: S LS { $$ = $1; $1->next = $2; }
LS: %empty { $$ = 0; }
S: SET VARNAME EXPR SEMI { $$ = stmt_create(STMT_SET, $2, $3, 0, 0, 0, 0); }
S: IFELSE EXPR THEN S S { $$ = stmt_create(STMT_IFELSE, 0, $2, $4, $5, 0, 0); }
S: IF EXPR THEN S { $$ = stmt_create(STMT_IF, 0, $2, $4, 0, 0, 0); }
S: REPEATN EXPR S { $$ = stmt_create(STMT_REPEATN, 0, $2, $3, 0, 0, 0); }
S: REPEATIF EXPR S { $$ = stmt_create(STMT_REPEATIF, 0, $2, $3, 0, 0, 0); }
S: PRINT EXPR SEMI { $$ = stmt_create(STMT_PRINT, $2, 0, 0, 0, 0, 0); }
S: PRINTNL EXPR SEMI { $$ = stmt_create(STMT_PRINTNL, $2, 0, 0, 0, 0, 0); }
S: LBRACE LS RBRACE { $$ = stmt_create(STMT_BLOCK, 0, 0, 0, 0, $2, 0); }
EXPR: EXPR PLUS EXPR { $$ = expr_create(EXPR_ADD, $1, $3); }
EXPR: EXPR MINUS EXPR { $$ = expr_create(EXPR_SUB, $1, $3); }
EXPR: EXPR TIMES EXPR { $$ = expr_create(EXPR_MULTIPLY, $1, $3); }
EXPR: EXPR DIVIDE EXPR { $$ = expr_create(EXPR_DIV, $1, $3); }
EXPR: EXPR MODULE EXPR { $$ = expr_create(EXPR_MOD, $1, $3); }
EXPR: EXPR LESS EXPR { $$ = expr_create(EXPR_LESS, $1, $3); }
EXPR: EXPR EQUAL EXPR { $$ = expr_create(EXPR_EQUAL, $1, $3); }
EXPR: EXPR GREATER EXPR { $$ = expr_create(EXPR_GREATER, $1, $3); }
EXPR: EXPR AND EXPR { $$ = expr_create(EXPR_AND, $1, $3); }
EXPR: EXPR OR EXPR { $$ = expr_create(EXPR_OR, $1, $3); }
EXPR: NOT EXPR { $$ = expr_create(EXPR_NOT, $2, 0); }
EXPR: VARNAME { $$ = $1; }
EXPR: NUMBER { $$ = expr_create_int_value($1); }
EXPR: STRING { $$ = expr_create_str_value($1); }
VARNAME: VNAME { $$ = expr_create_vname($1); }

%%

int main(int argc, char **argv) {
  const char *path = argc > 1 ? argv[1] : "program.txt";
  yyin = fopen(path, "r");
  if (!yyin) {
    fprintf(stderr, "error: cannot open '%s'\n", path);
    return 1;
  }

  int status = yyparse();
  fclose(yyin);
  if (status != 0)
    return 1;

  execute_stmt(parser_result);
  return 0;
}

void yyerror(const char *s) { fprintf(stderr, "error: %s\n", s); }
