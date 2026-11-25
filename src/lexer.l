%{
#include <stdlib.h>
#include <string.h>
#include "parser.tab.h"
%}

%option noyywrap nounput noinput

%%
IF                      { return IF; }
IFELSE                  { return IFELSE; }
SET                     { return SET; }
THEN                    { return THEN; }
ELSE                    { return ELSE; }
PRINTNL                 { return PRINTNL; }
PRINT                   { return PRINT; }
REPEATN                 { return REPEATN; }
REPEATIF                { return REPEATIF; }
[+]                     { return PLUS; }
[-]                     { return MINUS; }
[*]                     { return TIMES; }
[%]                     { return MODULE; }
[/]                     { return DIVIDE; }
[<]                     { return LESS; }
[>]                     { return GREATER; }
[=]                     { return EQUAL; }
[{]                     { return LBRACE; }
[}]                     { return RBRACE; }
[;]                     { return SEMI; }
[oO][rR]                { return OR; }
[aA][nN][dD]            { return AND; }
[nN][oO][tT]            { return NOT; }
["][[:print:]]*["]      { yylval.str = strdup(yytext); return STRING; }
[a-zA-Z]+               { yylval.str = strdup(yytext); return VNAME; }
[0-9]+                  { yylval.numb = atoi(yytext); return NUMBER; }
\n                      { }
.                       { }
%%
