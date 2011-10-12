BLANK [ \n\t]
DIGIT [0-9]
NUMBER {DIGIT}+"."?{DIGIT}*
CHAR [a-zA-Z0-9\[\]_-]
CHARORBLANK [\n\t a-zA-Z0-9\[\]_-]
STRINGENDING {CHARORBLANK}*{CHAR}
STRING {CHAR}{STRINGENDING}?

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

{BLANK}*\\caption{BLANK}* {
    return (Caption);
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

{BLANK}*\\cline{BLANK}* {
    return (CLine);
}

{BLANK}*\\alpha{BLANK}* {
    return (Alpha);
}

{BLANK}*\\Alpha{BLANK}* {
    return (ALPHA);
}

{BLANK}*\\beta{BLANK}* {
    return (Beta);
}

{BLANK}*\\Beta{BLANK}* {
    return (BETA);
}

{BLANK}*\\gamma{BLANK}* {
    return (Gamma);
}

{BLANK}*\\Gamma{BLANK}* {
    return (GAMMA);
}

{BLANK}*\\delta{BLANK}* {
    return (Delta);
}

{BLANK}*\\Delta{BLANK}* {
    return (DELTA);
}

{BLANK}*\\{CHAR}+{BLANK}* {
    return (LatexDirective);
}

{NUMBER} {
    yylval.number = atof(yytext);
    return (Number);
}

{STRING} {
    yylval.string = strdup(yytext);
    return (String);
}

. ;
