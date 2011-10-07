BLANK [ \n\t]
DIGIT [0-9]
NUMBER {DIGIT}+"."?{DIGIT}*
CHAR [a-zA-Z0-9_-]
CHARORBLANK [\n\t a-zA-Z0-9_-]
STRINGENDING {CHARORBLANK}*{CHAR}

%{
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

[|crl]+ {
    yylval.string = strdup(yytext);
    return(Format);
}

{NUMBER} {
    yylval.number = atof(yytext);
    return(Number);
}

{CHAR}{STRINGENDING}? {
    yylval.string = strdup(yytext);
    return(String);
}

\\begin\{tabular\}\{ {
    return(OpenBeginTab);
}

\} {
    return(CloseBeginTab);
}

\\end\{tabular\} {
    return(EndTab);
}

\\hline {
    return(HLine);
}

. ;
