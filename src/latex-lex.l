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
    return (NewLine);
}

{BLANK}*"&"{BLANK}* {
    return (NewCell);
}

[|crl]+ {
    yylval.string = strdup(yytext);
    return (Format);
}

{BLANK}*tabular{BLANK}* {
    return (Tabular);
}

{BLANK}*table{BLANK}* {
    return (TableTok);
}

{BLANK}*\\begin{BLANK}* {
    return (Begin);
}

{BLANK}*\\end{BLANK}* {
    return (End);
}

{BLANK}*\\multicolumn{BLANK}* {
    return (MultiColumn);
}

{BLANK}*\{{BLANK}* {
    return (Open);
}

{BLANK}*\}{BLANK}* {
    return (Close);
}

{BLANK}*\\hline{BLANK}* {
    return (HLine);
}

{NUMBER} {
    yylval.number = atof(yytext);
    return (Number);
}

{CHAR}{STRINGENDING}? {
    yylval.string = strdup(yytext);
    return (String);
}

. ;
