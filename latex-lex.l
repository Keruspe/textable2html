BLANK [ \n\t]
DIGIT [0-9]
NUMBER {DIGIT}+\.?{DIGIT}*

%{
    /* gwenael.pluchon@gmail.com */
    #include "y.tab.h"
    #include <string.h>
%}

%%
\n ;

{BLANK}*\\\\{BLANK}* {
    return(NewLine);
}

{BLANK}*"&"{BLANK}* {
    return(NewCell);
}

{NUMBER} {
    yylval.fval = atof(yytext);
    return(Number);
}

[\n\t a-zA-Z0-9_-]+ {
    yylval.sval = strdup(yytext);
    return(String);
}

\\begin\{tabular\}\{[|crl]+\}{BLANK}* {
    yytext[yyleng-1] = '\0';
    yylval.sval = strdup(yytext+16);
    return(BeginTab);
}

\\end\{tabular\} {
    return(EndTab);
}

. ;
