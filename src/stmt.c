#include "stmt.h"
#include "expr.h"
#include "table.h"

struct stmt * stmt_create(stmt_t kind,
    struct expr *var, struct expr *val,
    struct stmt *s_if, struct stmt *s_else,
    struct stmt *s_body, struct stmt *next)
{
  struct stmt *s = malloc(sizeof(*s));
  s->kind = kind;
  s->var = var;
  s->val = val;
  s->s_if = s_if;
  s->s_else = s_else;
  s->s_body = s_body;
  s->next = next;
  return s;
}

int execute_stmt(struct stmt *s) {
  if (!s) return 0;

  if (s->kind == STMT_SET) {
    int value = expr_evaluate(s->val);
    set_symbol((s->var)->vname, value);

  } else if (s->kind == STMT_IFELSE) {
    int result = expr_evaluate(s->val);
    if (result != 0)
      execute_stmt(s->s_if);
    else
      execute_stmt(s->s_else);

  } else if (s->kind == STMT_IF) {
    int result = expr_evaluate(s->val);
    if (result != 0)
      execute_stmt(s->s_if);

  } else if (s->kind == STMT_REPEATN) {
    int N = expr_evaluate(s->val);
    for (int i = 0; i < N; i++)
      execute_stmt(s->s_if);

  } else if (s->kind == STMT_REPEATIF) {
    while (expr_evaluate(s->val)) {
      execute_stmt(s->s_if);
    }

  } else if (s->kind == STMT_BLOCK) {
    execute_stmt(s->s_body);

  } else if (s->kind == STMT_PRINT) {
    print_expr(s->var, 0);

  } else if (s->kind == STMT_PRINTNL) {
    print_expr(s->var, 1);
  }

  return execute_stmt(s->next);
}
