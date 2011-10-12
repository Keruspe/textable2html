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

{BLANK}*\\\\{BLANK}*|{BLANK}*\\newline{BLANK}* {
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

\\alpha {
    return (Alpha);
}

\\Alpha {
    return (ALPHA);
}

\\beta {
    return (Beta);
}

\\Beta {
    return (BETA);
}

\\gamma {
    return (Gamma);
}

\\Gamma {
    return (GAMMA);
}

\\delta {
    return (Delta);
}

\\Delta {
    return (DELTA);
}

\\textbf{BLANK}* {
    return (Bold);
}

\\textit{BLANK}* {
    return (Italic);
}

\\textsc{BLANK}* {
    return (SmallCaps);
}

\\textrm{BLANK}* {
    return (Roman);
}

\\textsf{BLANK}* {
    return (Serif);
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
