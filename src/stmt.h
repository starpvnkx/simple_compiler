#ifndef STMT_H
#define STMT_H

#include <stdio.h>
#include <stdlib.h>

struct expr;

typedef enum {
  STMT_SET,
  STMT_EXPR,
  STMT_IF,
  STMT_IFELSE,
  STMT_REPEATN,
  STMT_REPEATIF,
  STMT_PRINT,
  STMT_PRINTNL,
  STMT_BLOCK
} stmt_t;

struct stmt {
  stmt_t kind;
  struct expr *var;
  struct expr *val;
  struct stmt *s_if;
  struct stmt *s_else;
  struct stmt *s_body;
  struct stmt *next;
};

struct stmt * stmt_create(
  stmt_t kind,
  struct expr *var,
  struct expr *val,
  struct stmt *s_if,
  struct stmt *s_else,
  struct stmt *s_body,
  struct stmt *next
);

int execute_stmt(struct stmt *s);

#endif
