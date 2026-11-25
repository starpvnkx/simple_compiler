#!/usr/bin/env bash
# Runs every tests/<suite>/*.simple program and checks:
#   - stdout matches  name.expected      (exact, byte for byte)
#   - stderr matches  name.expected_err  (only if that file exists)
#   - exit code is 0 for baseline/ and valid/, 1 for errors/
#
# Usage: scripts/run_tests.sh [path/to/simple] [suite ...]
#   default binary: ./simple
#   default suites: baseline valid errors

set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BIN="${1:-$ROOT/simple}"
shift || true
SUITES=("$@")
[ ${#SUITES[@]} -eq 0 ] && SUITES=(baseline valid errors)

if [ ! -x "$BIN" ]; then
  echo "run_tests: interpreter '$BIN' not found or not executable (run 'make' first)" >&2
  exit 2
fi

if [ -t 1 ]; then
  GREEN=$'\e[32m'; RED=$'\e[31m'; DIM=$'\e[2m'; RESET=$'\e[0m'
else
  GREEN=""; RED=""; DIM=""; RESET=""
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

pass=0
fail=0
failed=()

for suite in "${SUITES[@]}"; do
  dir="$ROOT/tests/$suite"
  [ -d "$dir" ] || continue

  case "$suite" in
    errors) want_code=1 ;;
    *)      want_code=0 ;;
  esac

  shopt -s nullglob
  programs=("$dir"/*.simple)
  shopt -u nullglob
  [ ${#programs[@]} -eq 0 ] && { echo "${DIM}[$suite] no tests${RESET}"; continue; }

  for prog in "${programs[@]}"; do
    name="$suite/$(basename "$prog" .simple)"
    base="${prog%.simple}"
    out="$TMP/out" err="$TMP/err"

    "$BIN" "$prog" >"$out" 2>"$err"
    code=$?

    reasons=()
    if [ ! -f "$base.expected" ]; then
      reasons+=("missing $(basename "$base").expected")
    elif ! cmp -s "$out" "$base.expected"; then
      reasons+=("stdout differs")
    fi
    if [ -f "$base.expected_err" ] && ! cmp -s "$err" "$base.expected_err"; then
      reasons+=("stderr differs")
    fi
    if [ "$code" -ne "$want_code" ]; then
      reasons+=("exit code $code, expected $want_code")
    fi

    if [ ${#reasons[@]} -eq 0 ]; then
      echo "${GREEN}PASS${RESET} $name"
      pass=$((pass + 1))
    else
      echo "${RED}FAIL${RESET} $name (${reasons[*]})"
      fail=$((fail + 1))
      failed+=("$name")
      if [ -f "$base.expected" ] && ! cmp -s "$out" "$base.expected"; then
        diff -u --label expected --label actual "$base.expected" "$out" | sed 's/^/    /'
      fi
      if [ -f "$base.expected_err" ] && ! cmp -s "$err" "$base.expected_err"; then
        diff -u --label expected_err --label actual_err "$base.expected_err" "$err" | sed 's/^/    /'
      fi
    fi
  done
done

total=$((pass + fail))
echo
echo "Summary: $pass/$total passed, $fail failed"
[ "$fail" -eq 0 ] || { printf '  %s\n' "${failed[@]}"; exit 1; }
