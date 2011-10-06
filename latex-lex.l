BLANK [ \n\t]
DIGIT [0-9]
NUMBER {DIGIT}+"."?{DIGIT}*
CHAR [a-zA-Z0-9_-]
CHARORBLANK [\n\t a-zA-Z0-9_-]
STRINGENDING {CHARORBLANK}*{CHAR}

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

{CHAR}{STRINGENDING}? {
    yylval.sval = strdup(yytext);
    return(String);
}

\\begin\{tabular\}\{ {
    return(OpenBeginTab);
}

[|crl]+ {
    yylval.sval = strdup(yytext);
    return(Format);
}

\} {
    return(CloseBeginTab);
}

\\end\{tabular\} {
    return(EndTab);
}

. ;
