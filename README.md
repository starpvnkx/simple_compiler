# SIMPLE Interpreter

An interpreter for **SIMPLE**, a small imperative teaching language, built with
**Flex** (lexer), **Bison** (parser) and **C** (AST and runtime).

SIMPLE has integer variables, `PRINT`/`PRINTNL`, `IF`/`IFELSE` conditionals and
`REPEATN`/`REPEATIF` loops. The final project for this repository adds
**fixed-size integer arrays** (`ARRAY a[5];`, `SET a[i] 10;`, `PRINT a[i + 1];`).
The plan for that work is in [`ROADMAP.md`](ROADMAP.md).

> **Status:** the base interpreter works and passes its regression tests
> (milestone M0). Array support is still in progress.

## Requirements

- `flex`
- `bison` 3.6 or newer
- `gcc`
- `make`

On Debian/Ubuntu: `sudo apt install flex bison gcc make`

## Build

```sh
make
```

This creates the `./simple` binary. Generated files go to `build/`.

## Run a program

```sh
./simple path/to/program.simple
# or
make run FILE=path/to/program.simple
```

With no argument, `./simple` reads `program.txt` from the current folder.

Example: save this as `factorial.simple`

```
SET n 1;
SET factorial 1;
REPEATIF n < 6 {
  SET factorial factorial * n;
  SET n n + 1;
}
PRINT "5!= ";
PRINTNL factorial;
```

```sh
$ ./simple factorial.simple
5!= 120
```

Program output goes to stdout. Errors (syntax errors, division by zero, unknown
variables) go to stderr, and the interpreter exits with code `1`.

## Test

```sh
make test
```

This runs every program in `tests/` and checks its output and exit code:

| Folder | Contains |
|--------|----------|
| `tests/baseline/` | The four example programs from the course PDF (regression tests) |
| `tests/valid/` | Array feature tests (in progress) |
| `tests/errors/` | Invalid-program tests that must fail with an error (in progress) |

Each test is a `name.simple` program with a `name.expected` file holding its
exact expected output. Error tests may also have a `name.expected_err` file.

## Language at a glance

| Statement | Example |
|-----------|---------|
| Assignment | `SET x 10;` |
| Print | `PRINT x + 1;` &nbsp; `PRINTNL "text";` (adds a newline) |
| Conditional | `IF x > 0 THEN PRINT "pos";` |
| If / else | `IFELSE x = 0 THEN PRINT x; PRINT 0 - x;` |
| Repeat N times | `REPEATN 3 PRINT "*";` |
| Repeat while | `REPEATIF x < 10 SET x x + 1;` |
| Block | `{ PRINT 1; PRINT 2; }` |

Operators: `+ - * / %`, `< > =`, `AND OR NOT`. There is no unary minus, so
write `0 - 1` for `-1`.

## Repository layout

```
src/        Interpreter source: lexer.l, parser.y, expr.[ch], stmt.[ch], table.[ch]
tests/      Test programs and expected output
scripts/    run_tests.sh, the test runner used by `make test`
docs/       Course PDFs and MODIFICATIONS.md (changes to the base code)
ROADMAP.md  Specification and schedule for the array extension
CHANGELOG.md  Record of every change to the repository
```

## Clean

```sh
make clean
```

## License

See [`LICENSE`](LICENSE).
