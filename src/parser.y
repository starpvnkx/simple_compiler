%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>

extern FILE *yyin;
extern int yylex(void);
void yyerror(const char*);

%}

%token  PLUS MINUS TIMES DIVIDE MODULE
        LESS GREATER EQUALS AND OR NOT
        LBRACE RBRACE DELIM
        SET IF ELSE IFELSE THEN REPEATIN REPEATIF PRINT PRINTNL

/*********************** Types of pseudovariables *************************/
%union {
    char *str;
    int num;
};

%token <num> NUM
%token <str> STR VAR

/********************** Precendence of operators **************************/
%left AND OR
%left PLUS MINUS
%left TIMES DIVIDE MODULE
%right NOT

%%
P : LS YYEOF
LS: S LS
LS: /* epsilon */ {$$ = 0;}
S: SET VARNAME EXPR DELIM
S: IFELSE EXPR THEN S S
S: IF EXPR THEN S
S: REPEATIN EXPR S
S: REPEATIF EXPR S
S: PRINT EXPR DELIM
S: PRINTNL EXPR DELIM
S: LBRACE LS RBRACE
EXPR: EXPR PLUS EXPR
EXPR: EXPR MINUS EXPR
EXPR: EXPR TIMES EXPR
EXPR: EXPR DIVIDE EXPR
EXPR: EXPR MODULE EXPR
EXPR: EXPR LESS EXPR
EXPR: EXPR EQUAL EXPR
EXPR: EXPR GREATER EXPR
EXPR: EXPR AND EXPR
EXPR: EXPR OR EXPR
EXPR: NOT EXPR
EXPR: VARNAME
EXPR: NUMBER
EXPR: STR
VARNAME: VAR 
%%

int main(void) {
    yyin = fopen("program.txt", "r");

    if (yyparse() == 0) {
        /* Execute statement */
    }
}

void yyerror(const char *s) { printf("error: %s\n", s); }
