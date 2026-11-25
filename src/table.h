#ifndef TABLE_H
#define TABLE_H

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

struct symbol {
  char* name;
  int value;
};

#define MAX_VAR 30
extern struct symbol table[MAX_VAR];
extern int num_sym;

int find_symbol(char *sname);

void set_symbol(char *sname, int svalue);

void print_table(void);

#endif
