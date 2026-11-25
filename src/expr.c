#include "expr.h"
#include "table.h"

struct expr *expr_create(
    expr_t kind,
    struct expr *left,
    struct expr *right) {
  struct expr *e = malloc(sizeof(*e));
  e->kind = kind;
  e->left = left;
  e->right = right;
  e->vname = 0;
  e->ivalue = 0;
  e->strvalue = 0;
  return e;
}

struct expr* expr_create_int_value(int value) {
  struct expr *e = expr_create(EXPR_NUMBER, 0, 0);
  e->ivalue = value;
  return e;
}

struct expr* expr_create_str_value(char* value) {
  /* Drop the surrounding quotes: "abc" -> abc */
  struct expr *e = expr_create(EXPR_STR, 0, 0);
  e->strvalue = strdup(&value[1]);
  e->strvalue[strlen(value) - 2] = '\0';
  return e;
}

struct expr* expr_create_vname(char* value) {
  struct expr *e = expr_create(EXPR_VNAME, 0, 0);
  e->vname = strdup(value);
  return e;
}

int expr_evaluate(struct expr* e) {
  if (!e) return 0;
  int l = expr_evaluate(e->left);
  int r = expr_evaluate(e->right);
  switch (e->kind) {
    case EXPR_ADD: return l + r;
    case EXPR_SUB: return l - r;
    case EXPR_MULTIPLY: return l * r;
    case EXPR_DIV:
      if (r != 0)
        return l / r;
      else {
        fprintf(stderr, "Runtime error: division by zero\n");
        exit(1);
      }
      break;
    case EXPR_MOD:
      if (r != 0)
        return l % r;
      else {
        fprintf(stderr, "Runtime error: division by zero\n");
        exit(1);
      }
      break;
    case EXPR_LESS: return l < r;
    case EXPR_GREATER: return l > r;
    case EXPR_EQUAL: return l == r;
    case EXPR_AND: return l && r;
    case EXPR_OR: return l || r;
    case EXPR_NOT: return !l;
    case EXPR_NUMBER: return e->ivalue;
    case EXPR_VNAME: {
      int index = find_symbol(e->vname);
      if (index >= 0)
        return table[index].value;
      else {
        fprintf(stderr, "Runtime error: unknown variable '%s'\n", e->vname);
        exit(1);
      }
    }
    case EXPR_STR: break;
  }
  return 0;
}

int print_expr(struct expr* e, int wnewline) {
  if (!e) return 0;
  if (e->kind == EXPR_NUMBER) {
    wnewline == 1 ?
      printf("%d\n", e->ivalue) :
      printf("%d", e->ivalue);
  } else if (e->kind == EXPR_STR) {
    wnewline == 1 ?
      printf("%s\n", e->strvalue) :
      printf("%s", e->strvalue);
  } else if (e->kind == EXPR_VNAME) {
    wnewline == 1 ?
      printf("%d\n", expr_evaluate(e)) :
      printf("%d", expr_evaluate(e));
  } else {
    int value = expr_evaluate(e);
    wnewline == 1 ?
      printf("%d\n", value) :
      printf("%d", value);
  }
  return 0;
}
