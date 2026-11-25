#ifndef EXPR_H
#define EXPR_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef enum {
  EXPR_ADD,
  EXPR_SUB,
  EXPR_MULTIPLY,
  EXPR_DIV,
  EXPR_MOD,
  EXPR_LESS,
  EXPR_GREATER,
  EXPR_EQUAL,
  EXPR_OR,
  EXPR_AND,
  EXPR_NOT,
  EXPR_VNAME,
  EXPR_NUMBER,
  EXPR_STR
} expr_t;

struct expr {
  expr_t kind;
  struct expr *left;
  struct expr *right;
  char* vname;
  int ivalue;
  char* strvalue;
};

struct expr *expr_create(
  expr_t kind,
  struct expr *left,
  struct expr *right
);

struct expr * expr_create_int_value(
  int value
);

struct expr * expr_create_str_value(
  char* value
);

struct expr * expr_create_vname(
  char* value
);

int expr_evaluate(struct expr* e);

int print_expr(struct expr* e,
               int wnewline);
#endif
