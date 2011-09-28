BLANK [ \n\t]
DIGIT [0-9]
NUMBER {DIGIT}+\.?{DIGIT}*

%{
    #include "y.tab.h"
%}

%%
{NUMBER} {
    yylval.fval = atof(yytext);
    return(Number);
}


