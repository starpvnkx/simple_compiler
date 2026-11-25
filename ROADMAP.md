# SIMPLE Interpreter: Integer Arrays (Roadmap & Specification)

> **Goal:** extend the SIMPLE interpreter (Flex + Bison + C) with fixed-size integer arrays. Programs must be able to declare arrays, assign to elements, read elements inside expressions, use any expression as an index, and stop with a clear message on invalid accesses.
>
> **Sources:** *Final Project: Adding Integer Arrays to the SIMPLE Language* (requirements + rubric) and *SIMPLE: Añadiendo condicionales y bucles* (base interpreter: `lexer.l`, `parser.y`, `expr.[ch]`, `stmt.[ch]`, `table.[ch]`).
>
> **Window:** Monday **Nov 23, 2026** to Monday **Nov 30, 2026** (final deadline).

---

## Table of Contents

1. [Scope and Deliverables](#1-scope-and-deliverables)
2. [Baseline: the Current SIMPLE Interpreter](#2-baseline-the-current-simple-interpreter)
3. [Language Specification for Arrays](#3-language-specification-for-arrays)
4. [Design: Changes per Component](#4-design-changes-per-component)
5. [Error Handling Specification](#5-error-handling-specification)
6. [Folder Structure](#6-folder-structure)
7. [Build and Test Workflow](#7-build-and-test-workflow)
8. [Test Plan](#8-test-plan)
9. [Rubric Coverage Matrix](#9-rubric-coverage-matrix)
10. [Schedule and Milestones (Nov 23 to Nov 30)](#10-schedule-and-milestones-nov-23-to-nov-30)
11. [Risks and Mitigations](#11-risks-and-mitigations)
12. [Final Submission Checklist](#12-final-submission-checklist)

---

## 1. Scope and Deliverables

### In scope (required)

| # | Feature | Example |
|---|---------|---------|
| F1 | Array declaration with a fixed size; every element starts at `0` | `ARRAY numbers[5];` |
| F2 | Element assignment with `SET` | `SET numbers[0] 10;` |
| F3 | Element access in `PRINT`/`PRINTNL` and arithmetic | `PRINT numbers[1] + numbers[2];` |
| F4 | Expression indices: constants, variables, arithmetic | `PRINT numbers[j + 1];` |
| F5 | Runtime error detection: undeclared array, negative index, index ≥ size | `PRINT numbers[5];` → error |

**Restrictions (from the assignment):** fixed size, zero-based indices, integer elements only.

### Deliverables

| # | Deliverable | Location in repo |
|---|-------------|------------------|
| D1 | Full source of the extended interpreter | `src/` + `Makefile` |
| D2 | Explanation of the changes to each component | `docs/MODIFICATIONS.md` |
| D3 | At least 5 test programs that show the new features | `tests/valid/` (we plan 9) |
| D4 | At least 1 test program with invalid array accesses | `tests/errors/` (we plan 7, including the required combined one) |

### Out of scope (do not build these)

- Multi-dimensional arrays, resizing, array literals (`{1,2,3}`), assigning a whole array to another, string arrays.
- Functions/procedures (SIMPLE has none).
- Compiling to machine code. This is still a tree-walking **interpreter**.

---

## 2. Baseline: the Current SIMPLE Interpreter

The repository currently holds only `LICENSE` and `.gitignore`. **Milestone M0 is to copy the base interpreter from the PDF into the repo and confirm it works before changing anything.**

### 2.1 Pipeline

```
program file ──► lexer.l (Flex) ──tokens──► parser.y (Bison) ──AST──► execute_stmt() ──► stdout
                                                                    │
                                                         expr_evaluate() ◄──► table.c (symbol table)
```

### 2.2 Base components

| File | Role | Key items |
|------|------|-----------|
| `lexer.l` | Tokenizer | Keywords `SET IF IFELSE THEN ELSE PRINT PRINTNL REPEATN REPEATIF`, operators `+ - * / % < > =`, `{ } ;`, `OR AND NOT` (any case), `STRING`, `VNAME` = `[a-zA-Z]+`, `NUMBER` = `[0-9]+` |
| `parser.y` | Grammar → AST | `%union { stmt*, expr*, char*, int }`, precedence: `AND OR` < `LESS GREATER EQUAL` (nonassoc) < `PLUS MINUS` < `TIMES DIVIDE MODULE` < `NOT` |
| `expr.h/.c` | Expression nodes | `struct expr { kind, left, right, vname, ivalue, strvalue }`, `expr_create*`, `expr_evaluate`, `print_expr` |
| `stmt.h/.c` | Statement nodes | `struct stmt { kind, var, val, s_if, s_else, s_body, next }`, `stmt_create`, `execute_stmt` |
| `table.h/.c` | Symbol table | `struct symbol { name, value }`, `table[MAX_VAR=30]`, `find_symbol`, `set_symbol` |

### 2.3 Known issues in the base code (fix while copying it in)

Write each of these up in `docs/MODIFICATIONS.md` under "Pre-existing fixes" so the grader can tell them apart from the array work.

| Issue | Where | Fix |
|-------|-------|-----|
| `int index = ...` declared right after `case EXPR_VNAME:` will not compile under C99/C11 | `expr.c` | Put the case body in `{ ... }` |
| Overflow check runs **after** writing `table[num_sym]`, so it can write past the end | `table.c` `set_symbol` | Check `num_sym >= MAX_VAR` **before** writing |
| `main` always opens `"program.txt"` | `parser.y` | Read `argv[1]` and fall back to `program.txt`. This lets the test runner pass each test file. |
| `fopen` result is never checked | `parser.y` | Print an error and exit with code 1 if the file is missing |
| Errors call `exit(0)` | `expr.c`, `table.c` | Use `exit(1)` so the test runner can detect failures (see §5) |
| `print_table` is declared but never defined | `table.h` | Define it (useful for debugging) or remove it |
| There is no unary minus, so `-1` cannot be written | grammar | Do **not** add it unless time allows. Write negative indices as `0 - 1` or through a variable (see §3.6). |

### 2.4 Base acceptance programs (from the PDF)

These four programs must give the expected output **before** any array work begins:

1. `IFELSE` positive/negative check → `12 es positivo`
2. Divisors of 24 with `REPEATN` + `IF`
3. Triangle of `*` with nested `REPEATN`
4. Factorial with `REPEATIF` → `5!= 120`

They go in `tests/baseline/` and are kept as **regression tests**: the array work must not break them.

---

## 3. Language Specification for Arrays

### 3.1 New lexical elements

| Lexeme | Token | Notes |
|--------|-------|-------|
| `ARRAY` | `ARRAY` | Keyword. The rule **must come before** the `VNAME` rule in `lexer.l`; when two rules match the same length, Flex picks the first. |
| `[` | `LBRACKET` | |
| `]` | `RBRACKET` | |

### 3.2 Grammar additions (EBNF)

```
S    ::= ... (existing statements)
       | "ARRAY" VNAME "[" NUMBER "]" ";"           (* array declaration *)
       | "SET" VNAME "[" EXPR "]" EXPR ";"         (* element assignment *)

EXPR ::= ... (existing expressions)
       | VNAME "[" EXPR "]"                        (* element access *)
```

Matching Bison rules (shown as a specification, **not** final code):

```
S:    ARRAY VNAME LBRACKET NUMBER RBRACKET SEMI          → STMT_ARRAY_DECL
S:    SET VNAME LBRACKET EXPR RBRACKET EXPR SEMI         → STMT_ARRAY_SET
EXPR: VNAME LBRACKET EXPR RBRACKET                       → EXPR_ARRAY_ACCESS
```

**Conflict analysis:** after `VNAME`, the parser must choose between reducing `VARNAME → VNAME` and shifting `[`. No `EXPR` can start with `[`, and no rule has `EXPR` directly followed by `[`, so the lookahead `[` always means shift. **Acceptance criterion: `bison -d parser.y` reports 0 shift/reduce and 0 reduce/reduce conflicts.**

### 3.3 Semantics

| Construct | Behavior |
|-----------|----------|
| `ARRAY a[n];` | Creates array `a` with `n` integer slots, all set to `0`. `n` must be an integer literal ≥ 1 (fixed size). |
| `SET a[i] e;` | Evaluates `i` and then `e`, checks the bounds, and stores the value of `e` in slot `i`. |
| `a[i]` inside an expression | Evaluates `i`, checks the bounds, and returns the stored integer. |
| Index | Any `EXPR`: literal, variable, arithmetic, or another array element (`a[a[0]]`). Logical/relational results (0/1) are also valid integers. |
| Valid range | `0 ≤ i < n` |
| Evaluation order | Index first, then value, then the bounds check, then the store |

### 3.4 Name rules (design decisions)

| Situation | Decision |
|-----------|----------|
| Scalars and arrays share one namespace | Yes. One name is either a scalar or an array, never both. |
| `ARRAY x[3];` when `x` is already an array | Runtime error: **redeclaration** |
| `ARRAY x[3];` when `x` is already a scalar | Runtime error: **name already used by a variable** |
| `SET x 5;` when `x` is an array | Runtime error: **cannot assign to an array without an index** |
| `x` (no brackets) in an expression when `x` is an array | Runtime error: **array used as a scalar** |
| `x[0]` when `x` is a scalar | Runtime error: **not an array** (reported like an undeclared array) |
| Declaration inside a loop | Runs every time the loop body runs, so it triggers the redeclaration error on the second pass. Write about this in the docs and declare arrays at the top of programs. |

### 3.5 Size limits

- `MAX_VAR` (currently 30) limits the total number of names (scalars + arrays).
- Array storage is allocated on the heap with `calloc(n, sizeof(int))`, which also gives the zero initialization. Set an upper limit (for example `MAX_ARRAY_SIZE 10000`) and report a clear error above it.

### 3.6 Negative indices without unary minus

SIMPLE has no unary minus, so the negative-index tests use:

```
SET k 0 - 1;
PRINT numbers[k];        (* variable holding -1 *)
PRINT numbers[2 - 3];    (* arithmetic giving -1 *)
```

---

## 4. Design: Changes per Component

This section is the skeleton for `docs/MODIFICATIONS.md` (deliverable D2). It covers every item in the assignment's "Implementation Requirements" list.

### 4.1 Lexer (`src/lexer.l`)

- Add `ARRAY { return ARRAY; }` **above** the `[a-zA-Z]+` rule.
- Add `"[" { return LBRACKET; }` and `"]" { return RBRACKET; }`.
- (Optional) turn on `%option yylineno` so error messages can show line numbers.

### 4.2 Parser (`src/parser.y`)

- Declare the new tokens: `ARRAY LBRACKET RBRACKET`.
- Add the 3 rules from §3.2.
- The declaration rule passes `NUMBER` through `expr_create_int_value` so the size is stored as an `expr*` in `val`.
- `main(int argc, char **argv)`: open `argv[1]` if it is given.

### 4.3 AST (`src/expr.h`, `src/stmt.h`)

New kinds. **The existing struct fields are enough; no new fields are needed:**

| New kind | Struct | Field use |
|----------|--------|-----------|
| `EXPR_ARRAY_ACCESS` | `struct expr` | `vname` = array name, `left` = index expression, `right` = `NULL` |
| `STMT_ARRAY_DECL` | `struct stmt` | `var` = `EXPR_VNAME` node (name), `val` = `EXPR_NUMBER` node (size) |
| `STMT_ARRAY_SET` | `struct stmt` | `var` = `EXPR_ARRAY_ACCESS` node (name + index), `val` = value expression |

New constructor: `expr_create_array_access(char *name, struct expr *index)`.

AST for `SET a[i + 1] a[i] * 2;`:

```
STMT_ARRAY_SET
 ├─ var: EXPR_ARRAY_ACCESS (vname="a")
 │        └─ left: EXPR_ADD(EXPR_VNAME i, EXPR_NUMBER 1)
 └─ val: EXPR_MULTIPLY
          ├─ EXPR_ARRAY_ACCESS (vname="a") └─ left: EXPR_VNAME i
          └─ EXPR_NUMBER 2
```

### 4.4 Symbol Table (`src/table.h`, `src/table.c`)

Extend `struct symbol`:

| Field | Type | Meaning |
|-------|------|---------|
| `name` | `char*` | (existing) |
| `value` | `int` | (existing) scalar value |
| `is_array` | `int` | `0` = scalar, `1` = array |
| `size` | `int` | number of elements (arrays only) |
| `values` | `int*` | heap storage from `calloc` (arrays only) |

New API:

| Function | Behavior |
|----------|----------|
| `void declare_array(char *name, int size)` | Checks redeclaration/name clash/size, then `calloc`s the storage |
| `int  get_array_element(char *name, int index)` | Checks that the array exists and that the index is in bounds, then returns the value |
| `void set_array_element(char *name, int index, int value)` | Same checks, then stores the value |
| `static void check_array_access(int pos, char *name, int index)` | Shared helper for the 3 error checks (keeps error messages identical) |

`set_symbol` and the `EXPR_VNAME` lookup also need the scalar-vs-array checks from §3.4.

### 4.5 Expression Evaluation (`src/expr.c`)

- `expr_evaluate` already evaluates `e->left` into `l` before its `switch`, so the new case is just `case EXPR_ARRAY_ACCESS: return get_array_element(e->vname, l);`.
- `case EXPR_VNAME`: raise an error if the symbol is an array.
- `print_expr` needs no change: array access goes through the generic `else` branch, which calls `expr_evaluate`.

### 4.6 Statement Execution (`src/stmt.c`)

- `STMT_ARRAY_DECL` → `declare_array(s->var->vname, s->val->ivalue)`.
- `STMT_ARRAY_SET` → `idx = expr_evaluate(s->var->left); v = expr_evaluate(s->val); set_array_element(s->var->vname, idx, v);`
- `STMT_SET` → reject the assignment when the target is an array (§3.4).

### 4.7 Error Handling

See §5. All array errors go through one function so the format is consistent.

---

## 5. Error Handling Specification

### 5.1 Policy

- Errors are detected at **runtime** (the interpreter has no separate semantic-analysis pass).
- On an error: write the message to **stderr**, stop, and exit with code **1**.
- Output printed before the error stays on stdout, so tests can check both the output before the failure and the error message.

### 5.2 Message catalogue

| Code | Trigger | Message format |
|------|---------|----------------|
| E1 | Access/assign to an undeclared array | `Runtime error: array 'NAME' has not been declared` |
| E2 | Index < 0 | `Runtime error: negative index IDX for array 'NAME'` |
| E3 | Index ≥ size | `Runtime error: index IDX out of bounds for array 'NAME' of size SIZE` |
| E4 | Redeclaration | `Runtime error: array 'NAME' is already declared` |
| E5 | Name clash scalar/array | `Runtime error: 'NAME' is already a variable` / `'NAME' is an array, use NAME[index]` |
| E6 | Size ≤ 0 or > max | `Runtime error: invalid size SIZE for array 'NAME'` |
| E7 | Symbol table full | `Runtime error: too many variables (max 30)` |

E1 to E3 are **required by the assignment**. E4 to E7 are extra robustness that supports the code-quality score.

> **Note:** errors stop the program, so one program can only show *one* runtime error. The required "invalid accesses" program (`e00_invalid_accesses.simple`) has several bad accesses with comments saying which one fires first. Separate programs `e01` to `e03` show each required error on its own (§8.2).

---

## 6. Folder Structure

Target layout when the project is finished:

```
simple_compiler/
├── README.md                  # How to build, run, and test; feature summary
├── ROADMAP.md                 # This document
├── LICENSE
├── .gitignore                 # + build/, simple (binary), *.tab.c, *.tab.h, lex.yy.c
├── Makefile                   # build, test, clean targets
│
├── src/                       # Interpreter source (deliverable D1)
│   ├── lexer.l                # Flex: + ARRAY, [, ]
│   ├── parser.y               # Bison: + 3 grammar rules, main(argc, argv)
│   ├── expr.h / expr.c        # + EXPR_ARRAY_ACCESS, expr_create_array_access
│   ├── stmt.h / stmt.c        # + STMT_ARRAY_DECL, STMT_ARRAY_SET
│   └── table.h / table.c      # + array fields, declare/get/set_array_element
│
├── build/                     # Generated files (gitignored)
│   ├── parser.tab.c / .h
│   ├── lex.yy.c
│   └── *.o
│
├── tests/
│   ├── baseline/              # The 4 PDF programs (regression)
│   │   ├── b01_ifelse.simple        + b01_ifelse.expected
│   │   ├── b02_divisors.simple      + .expected
│   │   ├── b03_triangle.simple      + .expected
│   │   └── b04_factorial.simple     + .expected
│   ├── valid/                 # Array feature tests (deliverable D3)
│   │   ├── t01_declare_init.simple  + .expected
│   │   ├── ...                      (see §8.1)
│   │   └── t09_conditions.simple    + .expected
│   └── errors/                # Invalid-access tests (deliverable D4)
│       ├── e00_invalid_accesses.simple + .expected + .expected_err
│       ├── ...                         (see §8.2)
│       └── e07_scalar_array_misuse.simple
│
├── scripts/
│   └── run_tests.sh           # Runs every .simple file and diffs stdout/stderr/exit code
│
└── docs/
    ├── MODIFICATIONS.md       # Changes per component (deliverable D2)
    ├── GRAMMAR.md             # Full updated grammar + token table
    └── TEST_REPORT.md         # Table of tests, purpose, result (pass/fail)
```

**Test file conventions**

- `name.simple`: the SIMPLE program.
- `name.expected`: exact expected **stdout**.
- `name.expected_err` (errors only): expected **stderr** line.
- Exit code: `0` for `baseline/` and `valid/`, `1` for `errors/`.

---

## 7. Build and Test Workflow

### 7.1 Toolchain

| Tool | Purpose | Check |
|------|---------|-------|
| `flex` | Lexer generator | `flex --version` |
| `bison` ≥ 3.0 | Parser generator (`YYEOF` needs a recent Bison) | `bison --version` |
| `gcc` | C compiler, `-std=c11 -Wall -Wextra` | `gcc --version` |
| `make` | Build | `make --version` |

### 7.2 Makefile targets (spec)

| Target | Does |
|--------|------|
| `make` / `make all` | `bison -d` → `flex` → `gcc` → `./simple` binary |
| `make test` | Builds, then runs `scripts/run_tests.sh` over `baseline/`, `valid/`, `errors/` |
| `make run FILE=path` | `./simple path` |
| `make clean` | Removes `build/` and the binary |

### 7.3 Test runner (spec)

For every `*.simple`: run `./simple file`, save stdout, stderr, and the exit code, and compare them with `.expected` / `.expected_err` / the expected exit code. Print `PASS`/`FAIL` per test and a summary. Exit with a non-zero code if any test fails.

### 7.4 Git workflow

- One branch per milestone (`m1-lexer-parser`, `m2-runtime`, ...), merged to `main` when its Definition of Done is met.
- Commit after each task with a short message (`lexer: add ARRAY, [, ] tokens`).
- Tag the submitted version: `v1.0-final`.

---

## 8. Test Plan

### 8.1 Valid programs (≥ 5 required, 9 planned)

| ID | File | Shows | Rubric area |
|----|------|-------|-------------|
| t01 | `t01_declare_init` | Declare 2 arrays of different sizes, print **every** element → all `0` | Declaration & Initialization |
| t02 | `t02_assign` | `SET a[0] 10; SET a[1] 20; SET a[2] 30;` overwrite an element, print | Element Assignment |
| t03 | `t03_access_arith` | `PRINT a[1] + a[2];`, `SET x a[0] * 2 - a[1];`, elements in `/` and `%` | Element Access |
| t04 | `t04_index_exprs` | Indices: constant, variable `a[i]`, arithmetic `a[j + 1]`, `a[n - 1]`, nested `a[a[0]]`, index from `%` | Expression-Based Indices |
| t05 | `t05_traverse_fill` | Fill `squares[i] = i*i` with `REPEATIF i < 10`, then print all of them with `REPEATN` | Array Traversal |
| t06 | `t06_sum_max_min` | Traverse to compute sum, max, min, and average | Traversal + Access |
| t07 | `t07_bubble_sort` | Sort an array with nested loops and `IF`, swap through a temp variable | Traversal (advanced) |
| t08 | `t08_multi_arrays` | Copy array A into B in reverse, element-wise `C[i] = A[i] + B[i]` | Multiple arrays |
| t09 | `t09_conditions` | Elements in `IF`/`IFELSE`/`REPEATIF` conditions with `AND`/`OR`/`NOT`; count the even values | Access in all contexts |

Optional extras if there is time: Fibonacci table, prime sieve, histogram using an array as counters (`count[x % 5]`).

### 8.2 Invalid programs (≥ 1 required, 7 planned)

| ID | File | Expected error |
|----|------|----------------|
| e00 | `e00_invalid_accesses` | **Required combined program**: valid output first, then a bad access. Comments list the other bad accesses. |
| e01 | `e01_undeclared` | E1: `PRINT ghost[0];` |
| e02 | `e02_negative_index` | E2: `SET k 0 - 1; PRINT a[k];` |
| e03 | `e03_out_of_range` | E3: `ARRAY a[5]; SET a[5] 1;` (index == size) |
| e04 | `e04_off_by_one_loop` | E3 inside a traversal loop that uses `<=` instead of `<` |
| e05 | `e05_redeclaration` | E4: `ARRAY a[3]; ARRAY a[4];` |
| e06 | `e06_invalid_size` | E6: `ARRAY a[0];` |
| e07 | `e07_scalar_array_misuse` | E5: `SET a 5;` where `a` is an array |

Also add one test each for E1 and E3 in **write** context (`SET`), since the rubric asks for detection on both reads and writes.

### 8.3 Regression

All 4 `tests/baseline/` programs must still pass after every milestone.

---

## 9. Rubric Coverage Matrix

| Rubric category | Pts | How we earn "Exemplary" | Evidence |
|-----------------|-----|-------------------------|----------|
| Array Declaration & Initialization | 15 | `calloc` zero-fill, any size ≥ 1, several arrays | t01, e05, e06 |
| Array Element Assignment | 10 | `SET a[idx] expr;` with any value expression | t02, t07, t08 |
| Array Element Access | 10 | Works in PRINT, PRINTNL, arithmetic, conditions, loop counts | t03, t09 |
| Expression-Based Indices | 15 | Constant, variable, arithmetic, nested indices | t04, t05 |
| Array Traversal | 10 | `REPEATIF`/`REPEATN` loops over all elements, sort, aggregates | t05, t06, t07, t08 |
| Index Bounds & Error Detection | 15 | E1/E2/E3 on read **and** write, with clear messages | e00 to e07 |
| Testing & Demonstration | **20** | 9 valid + 7 invalid + 4 regression, automatic runner, `TEST_REPORT.md` | `tests/`, `scripts/run_tests.sh` |
| Code Quality & Documentation | 5 | Clean code, comments only on new parts, `MODIFICATIONS.md`, `README.md` | `docs/` |
| **Total** | **100** | | |

---

## 10. Schedule and Milestones (Nov 23 to Nov 30)

> Short window: **8 days**, and the final day is reserved for submission. Each milestone has a **Definition of Done (DoD)**. Do not start the next milestone until the current DoD passes.

### Overview

| Day | Date | Milestone | Focus |
|-----|------|-----------|-------|
| Mon | **Nov 23** | **M0: Baseline** | Repo setup, copy in the base interpreter, build, baseline tests |
| Tue | **Nov 24** | **M1: Front end** | Lexer + AST + parser for arrays (parses, not run yet) |
| Wed | **Nov 25** | **M2: Runtime core** | Symbol table + declaration/assignment/access execute |
| Thu | **Nov 26** | **M3: Indices & errors** | Expression indices fully working, all error checks |
| Fri | **Nov 27** | **M4: Test suite** | All valid/error programs, test runner, all green |
| Sat | **Nov 28** | **M5: Documentation** | `MODIFICATIONS.md`, `GRAMMAR.md`, `README.md`, `TEST_REPORT.md` |
| Sun | **Nov 29** | **M6: Hardening & freeze** | Buffer, edge cases, rubric self-audit, code freeze |
| Mon | **Nov 30** | **🏁 DEADLINE** | Clean-clone check, tag `v1.0-final`, submit |

```
Nov 23  24  25  26  27  28  29  30
 M0 ─┐
     M1 ─┐
         M2 ─┐
             M3 ─┐
                 M4 ─┐
                     M5 ─┐
                         M6 ─┐
                             SUBMIT
```

### M0: Baseline (Mon Nov 23)

- [x] Install/check `flex`, `bison` (≥ 3.0), `gcc`, `make`
- [x] Create the folder structure from §6
- [x] Copy `lexer.l`, `parser.y`, `expr.[ch]`, `stmt.[ch]`, `table.[ch]` from the PDF into `src/`
- [x] Apply the base-code fixes from §2.3 and list them for the docs
- [x] Write the `Makefile` (all/test/run/clean)
- [x] Update `.gitignore` for generated files
- [x] Add the 4 PDF programs to `tests/baseline/` with `.expected` output
- [x] Write a first version of `scripts/run_tests.sh`

**DoD:** `make` builds with no warnings, `make test` passes 4/4 baseline tests, and the work is committed.

### M1: Front end (Tue Nov 24)

- [ ] Lexer: `ARRAY` (before `VNAME`), `[`, `]`
- [ ] `expr.h`: `EXPR_ARRAY_ACCESS` + `expr_create_array_access`
- [ ] `stmt.h`: `STMT_ARRAY_DECL`, `STMT_ARRAY_SET`
- [ ] `parser.y`: tokens + the 3 rules from §3.2
- [ ] Check that Bison reports **0 conflicts**
- [ ] Temporary: `execute_stmt` ignores the new kinds so programs parse without crashing

**DoD:** all t01 to t09 drafts **parse** without `syntax error`, Bison reports 0 conflicts, and baseline tests still pass.

### M2: Runtime core (Wed Nov 25)

- [ ] Extend `struct symbol` (`is_array`, `size`, `values`)
- [ ] `declare_array` with `calloc` (zero-fill)
- [ ] `get_array_element` / `set_array_element` (no bounds checks yet)
- [ ] `expr_evaluate`: `EXPR_ARRAY_ACCESS` case
- [ ] `execute_stmt`: `STMT_ARRAY_DECL`, `STMT_ARRAY_SET`
- [ ] Write t01, t02, t03 with `.expected`

**DoD:** t01, t02, t03 pass, and baseline still passes.

### M3: Indices & errors (Thu Nov 26)

- [ ] Check variable, arithmetic, and nested indices (t04)
- [ ] `check_array_access` helper: E1, E2, E3
- [ ] E4 to E7 (redeclaration, name clash, invalid size, table full)
- [ ] Send all errors to stderr with `exit(1)`, using the message formats from §5.2
- [ ] Write t04 and e01 to e03

**DoD:** t04 + e01 to e03 pass, and each required error (E1/E2/E3) is detected on both **read and write**.

### M4: Test suite (Fri Nov 27)

- [ ] Write t05 to t09 (traversal, aggregates, sort, multiple arrays, conditions)
- [ ] Write e00 (required combined invalid program) and e04 to e07
- [ ] Finish the test runner: stdout + stderr + exit-code checks, summary line
- [ ] Fix every bug found

**DoD:** `make test` shows **all PASS** (4 baseline + 9 valid + 8 errors).

### M5: Documentation (Sat Nov 28)

- [ ] `docs/MODIFICATIONS.md`: one section per component (Lexer, Parser, AST, Symbol Table, Expression Evaluation, Statement Execution, Error Handling) + pre-existing fixes, with short before/after snippets
- [ ] `docs/GRAMMAR.md`: full grammar, token table, precedence
- [ ] `docs/TEST_REPORT.md`: table of every test, its purpose, the rubric item it covers, and its result
- [ ] `README.md`: requirements, build, run, test, example session
- [ ] Short comments in the source **only** on new/changed code

**DoD:** someone who has never seen the repo can build, run, and understand the changes using only `README.md` + `docs/`.

### M6: Hardening & freeze (Sun Nov 29)

- [ ] Edge cases: size-1 array, last valid index `n - 1`, index from a relational result, very large size, arrays + `MAX_VAR` limit
- [ ] Build with `-Wall -Wextra` and fix all warnings; optionally run under `valgrind`
- [ ] Self-grade against the §9 rubric matrix, line by line
- [ ] **Code freeze** at the end of the day (docs and test typo fixes only after this)

**DoD:** rubric self-audit shows "Exemplary" evidence for all 8 categories, and the work is tagged `v1.0-rc`.

### Deadline day (Mon Nov 30)

- [ ] Fresh `git clone` into a temporary folder → `make && make test` → all green
- [ ] Final review of the §12 checklist
- [ ] Tag `v1.0-final`, then package/submit (repo link or zip as the course requires)

### Must be done before the deadline (critical path)

1. **By Nov 23:** the base interpreter builds and runs (everything else depends on this).
2. **By Nov 25:** declaration, assignment, and access work end to end (35/100 pts of core features).
3. **By Nov 26:** expression indices + E1/E2/E3 (30/100 pts).
4. **By Nov 27:** ≥ 5 valid + ≥ 1 invalid test programs passing (20/100 pts, the biggest single category).
5. **By Nov 28:** modification explanation written (deliverable D2).
6. **Nov 29** is the only buffer day. If a milestone slips, use it and drop the optional extras (§8.1 extras, line numbers, `print_table`).

---

## 11. Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Base code from the PDF has typos or does not compile | Blocks everything | Do M0 first and fix the issues in §2.3; baseline tests catch regressions |
| `ARRAY` gets lexed as `VNAME` | Declarations fail with a syntax error | Put the keyword rule before `[a-zA-Z]+` |
| Bison shift/reduce conflicts | Wrong parse | Use the conflict analysis in §3.2; run `bison -Wcounterexamples` if any appear |
| No unary minus makes negative-index tests awkward | Weaker E2 demo | Use `0 - 1` and variables (§3.6) |
| Errors stop execution, so one program cannot show all errors | Rubric reviewer may want to see all 3 | e00 with comments + one program per error (§5, §8.2) |
| Arrays declared inside loops | Redeclaration error at runtime | Document "declare at top", covered by e05 |
| The window is only 8 days | Late submission | Strict daily DoD, Nov 29 buffer, optional items clearly marked |
| Old Bison without `YYEOF` | Build fails | Require Bison ≥ 3.6 or replace `YYEOF` with the standard end-of-input |

---

## 12. Final Submission Checklist

- [ ] `make` builds cleanly from a fresh clone
- [ ] `make test`: every baseline, valid, and error test passes
- [ ] `ARRAY name[N];` declares an array with all elements set to zero
- [ ] `SET name[expr] expr;` assigns
- [ ] `name[expr]` works in PRINT, PRINTNL, arithmetic, conditions, and loop counts
- [ ] Constant, variable, arithmetic, and nested indices all work
- [ ] Undeclared, negative, and ≥ size accesses are detected (read **and** write)
- [ ] ≥ 5 valid test programs (9 planned) with expected outputs
- [ ] ≥ 1 invalid-access test program (e00 + 7 others)
- [ ] `docs/MODIFICATIONS.md` covers all 7 components + pre-existing fixes
- [ ] `README.md` explains build/run/test
- [ ] No generated files or binaries committed
- [ ] Tagged `v1.0-final`
