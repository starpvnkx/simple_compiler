%{
#include <stdlib.h>
#include "parser.tab.h"
%}

%option noyywrap

%%
IF                      { return IF; }
IFELSE                  { return IFELSE; }
SET                     { return SET; }
THEN                    { return THEN; }
ELSE                    { return ELSE; }
PRINTNL                 { return PRINTNL; }
PRINT                   { return PRINT; }
REPEATIN                { return REPEATIN; }
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
[;]                     { return DELIM; }
[i?:or]                 { return OR; }
[i?and]                 { return AND; }
[i?:not]                { return NOT; }
["][[:print:]]*["]      { 
                            yylval.str = yytext;
                            return STR;
                        }
[a-zA-Z]+               { 
                            yylval.str = yytext;
                            return VAR;
                        }
[0-9]+                  { 
                            yylval.num = atoi(yytext);
                            return NUM;    
                        }
\n                      { }
.                       { }
%%
