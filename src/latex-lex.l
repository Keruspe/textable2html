BLANK [ \t]
DIGIT [0-9]
NUMBER {DIGIT}+"."?{DIGIT}*
CHAR [a-zA-Z0-9\[\]_-]
CHARORBLANK [\t a-zA-Z0-9\[\]_-]
STRINGENDING {CHARORBLANK}*{CHAR}
STRING {CHAR}{STRINGENDING}?
NEWLINE \\\\
NEWCELL "&"
FORMAT [clr|]

%{
    #include "y.tab.h"
    #include <string.h>

    extern int nb_line;
%}

%%
{BLANK}*\n{BLANK}* {
    ++nb_line;
}

{BLANK}*{NEWLINE}{BLANK}*|{BLANK}*\\newline{BLANK}* {
    return (NewLine);
}

{BLANK}*{NEWCELL}{BLANK}* {
    return (NewCell);
}

{BLANK}*{FORMAT}+{BLANK}* {
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
    return (MultiColumnTok);
}

{BLANK}*\\caption{BLANK}* {
    return (CaptionTok);
}

{BLANK}*\{{BLANK}* {
    return (Open);
}

{BLANK}*\} {
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

\\emph{BLANK}* {
    return (Emphasis);
}

\\{CHAR}+ {
    return (LatexDirective);
}

{DIGIT}+ {
    yylval.string = strdup (yytext);
    return (IntegerTok);
}

{NUMBER} {
    yylval.string = strdup (yytext);
    return (NumberTok);
}

{STRING} {
    yylval.string = strdup (yytext);
    return (String);
}

{BLANK}+ {
    yylval.string = strdup (yytext);
    return (Blank);
}

<<EOF>> {
    yyterminate ();
}
