# SIMPLE interpreter build
#
#   make            build ./simple
#   make test       build, then run every test under tests/
#   make run FILE=path/to/program.simple
#   make clean      remove build/ and the binary

CC      = gcc
BISON   ?= bison
FLEX    ?= flex

SRC_DIR   := src
BUILD_DIR := build
BIN       := simple

CFLAGS  ?= -std=c11 -Wall -Wextra -O2
# strdup() is POSIX, not ISO C11.
CPPFLAGS += -D_POSIX_C_SOURCE=200809L -I$(SRC_DIR) -I$(BUILD_DIR)

C_SRCS  := $(SRC_DIR)/expr.c $(SRC_DIR)/stmt.c $(SRC_DIR)/table.c
GEN_C   := $(BUILD_DIR)/parser.tab.c $(BUILD_DIR)/lex.yy.c
OBJS    := $(patsubst $(SRC_DIR)/%.c,$(BUILD_DIR)/%.o,$(C_SRCS)) \
           $(GEN_C:.c=.o)
HEADERS := $(wildcard $(SRC_DIR)/*.h) $(BUILD_DIR)/parser.tab.h

.PHONY: all test run clean

all: $(BIN)

$(BIN): $(OBJS)
	$(CC) $(CFLAGS) -o $@ $^

$(BUILD_DIR):
	mkdir -p $@

# Bison produces both the parser and the token header used by the lexer.
$(BUILD_DIR)/parser.tab.c $(BUILD_DIR)/parser.tab.h: $(SRC_DIR)/parser.y | $(BUILD_DIR)
	$(BISON) -d -Wall -o $(BUILD_DIR)/parser.tab.c $<

$(BUILD_DIR)/lex.yy.c: $(SRC_DIR)/lexer.l $(BUILD_DIR)/parser.tab.h | $(BUILD_DIR)
	$(FLEX) -o $@ $<

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c $(HEADERS) | $(BUILD_DIR)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<

$(BUILD_DIR)/%.o: $(BUILD_DIR)/%.c $(HEADERS)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<

test: $(BIN)
	./scripts/run_tests.sh ./$(BIN)

run: $(BIN)
	@if [ -z "$(FILE)" ]; then echo "usage: make run FILE=path/to/program.simple"; exit 2; fi
	./$(BIN) $(FILE)

clean:
	rm -rf $(BUILD_DIR) $(BIN)
