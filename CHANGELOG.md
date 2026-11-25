# Changelog

All notable changes to this repository are recorded here.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Newest entries go at the top. Each entry lists what changed and where.

## [Unreleased]

### 2026-11-25: README

#### Added
- `README.md`: what the repository is, requirements, build/run/test commands,
  a runnable example, a SIMPLE language quick reference, and the folder layout.

#### Known issues
- `src/lexer.l`: the `STRING` rule `["][[:print:]]*["]` is greedy, so two
  strings on the same line (e.g. `PRINT "a"; PRINT "b";`) lex as one string
  `a"; PRINT "b`. Not fixed yet.

### 2026-11-25: M0 Baseline completed

#### Added
- `Makefile` with `all`, `test`, `run FILE=...` and `clean` targets. Generated
  files (`parser.tab.[ch]`, `lex.yy.c`, `*.o`) go to `build/`; the binary is `./simple`.
- `scripts/run_tests.sh`: runs every `tests/<suite>/*.simple`, compares stdout
  with `.expected`, stderr with `.expected_err` (when present), and checks the
  exit code (`0` for `baseline/` and `valid/`, `1` for `errors/`). Prints
  PASS/FAIL per test with a diff on failure, plus a summary; exits non-zero if any test fails.
- `tests/baseline/b01_ifelse`, `b02_divisors`, `b03_triangle`, `b04_factorial`:
  the four PDF example programs with expected output (regression tests).
- Empty `tests/valid/` and `tests/errors/` folders (kept with `.gitkeep`).
- `docs/MODIFICATIONS.md` with the "Pre-existing fixes" section (P1 to P17).
- `CHANGELOG.md` (this file).

#### Changed
- `src/expr.c`, `src/table.c`: runtime error messages now go to stderr, end
  with a newline, and use the `Runtime error: ...` format
  (`division by zero`, `unknown variable 'NAME'`, `too many variables (max 30)`).
- `src/parser.y`: `yyerror` writes to stderr; `main` closes the input file and
  exits with code 1 on a syntax error.
- `src/parser.y`: `%empty` for the empty `LS` rule and `%precedence NOT`
  (removes the Bison warnings, same grammar behavior).
- `src/lexer.l`: `%option nounput noinput` (removes the gcc unused-function warnings).
- `.gitignore`: ignores `build/`, the `simple` binary and Flex/Bison output.
- `ROADMAP.md`: ticked the M0 tasks.

#### Verified
- `make` from clean builds with no warnings (gcc `-std=c11 -Wall -Wextra`, `bison -Wall`).
- `make test`: 4/4 baseline tests pass.

### 2026-11-24: Base interpreter imported (commit `fbe35c7`)
- Added the base SIMPLE interpreter from the course PDF in `src/`, with the
  fixes P1 to P10 and P12 from `docs/MODIFICATIONS.md` already applied.
