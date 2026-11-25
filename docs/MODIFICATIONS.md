# Modifications to the SIMPLE Interpreter

This document explains every change made to the base SIMPLE interpreter from
*SIMPLE: Añadiendo condicionales y bucles* (`docs/simple_language.pdf`).

It has two parts:

1. **Pre-existing fixes**: bugs and portability problems in the code as printed
   in the PDF. They are unrelated to arrays and were fixed during milestone M0
   so the base interpreter builds cleanly and can be tested automatically.
2. **Array extension**: the changes required by the final project
   (`docs/final_project_simple.pdf`). *To be written in milestone M5.*

---

## 1. Pre-existing fixes

### 1.1 Correctness

| # | File | Problem in the PDF code | Fix |
|---|------|-------------------------|-----|
| P1 | `lexer.l` | `yylval.str = yytext;` stores a pointer into Flex's internal buffer, which is overwritten by later tokens. Variable names and strings could silently change. | `yylval.str = strdup(yytext);` for `STRING` and `VNAME`, plus `#include <string.h>`. |
| P2 | `expr.c` | `int index = ...` declared directly after `case EXPR_VNAME:`. A declaration cannot follow a label in C99/C11, so it does not compile. | Wrapped the case body in `{ ... }`. |
| P3 | `expr.c` | `expr_create` left `vname`, `ivalue` and `strvalue` uninitialized. | Initialized all three to `0`. |
| P4 | `expr.c` | `switch` did not handle `EXPR_STR` (compiler warning). | Added `case EXPR_STR: break;`. |
| P5 | `expr.c` | `print_expr` is declared `int` but returned nothing. | Added `return 0;`. |
| P6 | `stmt.c` | `execute_stmt` is declared `int` but the final `execute_stmt(s->next);` result was not returned. | `return execute_stmt(s->next);`. |
| P7 | `table.c` | `set_symbol` wrote `table[num_sym]` **before** checking `num_sym > MAX_VAR`, so the 31st variable was written past the end of the array. | Check `num_sym >= MAX_VAR` before writing. |
| P8 | `table.h` | `print_table` was declared but never defined. | Defined it in `table.c` (prints `name = value`, used for debugging). |

### 1.2 Usability and testability

| # | File | Problem in the PDF code | Fix |
|---|------|-------------------------|-----|
| P9 | `parser.y` | `main` always opened `"program.txt"`. | `main(int argc, char **argv)` opens `argv[1]` and falls back to `program.txt`. |
| P10 | `parser.y` | The result of `fopen` was never checked (crash on a missing file). | Prints `error: cannot open 'FILE'` to stderr and exits with code 1. |
| P11 | `parser.y` | A syntax error still exited with code 0, and the file was never closed. | `main` closes the file and returns 1 when `yyparse()` fails. |
| P12 | `expr.c`, `table.c` | Runtime errors called `exit(0)`, so a failing program looked successful. | All runtime errors use `exit(1)`. |
| P13 | `expr.c`, `table.c`, `parser.y` | Error messages were printed to stdout, mixed with the program output, and some had no trailing newline. | All errors go to **stderr**, end with `\n`, and use the `Runtime error: ...` format from ROADMAP §5: `division by zero`, `unknown variable 'NAME'`, `too many variables (max 30)`. Syntax errors print `error: MESSAGE`. |

### 1.3 Build warnings

The goal is a build with no warnings under `gcc -std=c11 -Wall -Wextra` and `bison -Wall`.

| # | File | Warning | Fix |
|---|------|---------|-----|
| P14 | `parser.y` | Bison: `empty rule without %empty` | `LS: %empty { $$ = 0; }` |
| P15 | `parser.y` | Bison: `useless associativity for NOT` | `%right NOT` → `%precedence NOT` (same precedence, no associativity) |
| P16 | `lexer.l` | gcc: `yyunput` / `input` defined but not used | `%option noyywrap nounput noinput` |
| P17 | `Makefile` | `strdup` is POSIX, not ISO C11, so `-std=c11` hides its declaration | Compile with `-D_POSIX_C_SOURCE=200809L` |

### 1.4 Notes on the baseline expected output

The output tables in the PDF do not match what the printed programs actually
produce in two places. The `.expected` files in `tests/baseline/` follow the
real behavior of the programs, not the PDF tables:

- **Triangle (`b03`)**: the PDF shows `* * * ...` with spaces, but the program
  prints `"*"`, so each line is `********` with no spaces.
- **Factorial (`b04`)**: the PDF shows `5! = 120`, but the program prints
  `"5!= "`, so the output is `5!= 120`.

`b01` and `b04` end without a newline, because they only use `PRINT`.

---

## 2. Array extension

*To be written in milestone M5* (lexer, parser, AST, symbol table, expression
evaluation, statement execution, error handling). See `ROADMAP.md` §4.
