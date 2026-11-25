#include "table.h"

struct symbol table[MAX_VAR];
int num_sym = 0;

int find_symbol(char *sname) {
  for (int i = 0; i < num_sym; i++)
    if (strcmp(table[i].name, sname) == 0)
      return i;
  return -1;
}

void set_symbol(char *sname, int svalue) {
  int pos = find_symbol(sname);
  if (pos < 0) {
    /* Check the limit before writing, so we never write past the table. */
    if (num_sym >= MAX_VAR) {
      printf("Var limit");
      exit(1);
    }
    table[num_sym].name = sname;
    table[num_sym].value = svalue;
    num_sym++;
  } else {
    table[pos].name = sname;
    table[pos].value = svalue;
  }
}

void print_table(void) {
  for (int i = 0; i < num_sym; i++)
    printf("%s = %d\n", table[i].name, table[i].value);
}
