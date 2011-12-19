BLANK [ \t]
DIGIT [0-9]
NUMBER {DIGIT}+"."?{DIGIT}*
CHAR [a-zA-Z0-9_-]
/* Characters auhorizes at the first or last position in a string */
STRINGLIMIT [^\ \\{}&\n$]+
/* Everything but the first character. Ends with a string limit, allow spaces inside. */
STRINGENDING [^\\{}&\n$]*{STRINGLIMIT}
/* One character alone or with a string ending */
STRING {STRINGLIMIT}{STRINGENDING}?
NEWLINE \\\\
NEWCELL "&"
FORMAT [clr|]
COMMENT \%[^\n]*

%option noinput
%option nounput

%{
    #include "y.tab.h"
    #include <string.h>

    extern int nb_line;
%}

%%
{BLANK}*\n{BLANK}* {
    ++nb_line;
}

{COMMENT} {
    /* Ignore it */
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
    return (Caption);
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

{BLANK}*\\vspace{BLANK}* {
    return (VSpace);
}

{BLANK}*\\label{BLANK}* {
    return (Label);
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

\\% {
    return (Percent);
}

"$" {
    /* Just ignore it */
}

\\textbf{BLANK}*|\\bf{BLANK}* {
    return (Bold);
}

\\textit{BLANK}*|\\it{BLANK}* {
    return (Italic);
}

\\textsc{BLANK}*|\\sc{BLANK}* {
    return (SmallCaps);
}

\\textrm{BLANK}*|\\rm{BLANK}* {
    return (Roman);
}

\\textsf{BLANK}*|\\sf{BLANK}* {
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
