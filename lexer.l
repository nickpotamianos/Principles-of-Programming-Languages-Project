%{

#include "parser.tab.h"
#include <stdio.h>

%}

%x comment
%option yylineno

DIGIT        [0-9]
LETTER       [a-zA-Z]
ALPHANUM     {LETTER}|{DIGIT}|_
STRING       [^\"]*

%%

"<" { return OPEN_ANGLE; }
">" { return CLOSE_ANGLE; }
"\/" { return SLASH; }
"<!--" { BEGIN(comment); }
<comment>"-->" { BEGIN(INITIAL); }
<comment>.|\n { /* ignore comments */ }

"LinearLayout" { return LINEAR_LAYOUT; }
"RelativeLayout" { return RELATIVE_LAYOUT; }
"TextView" { return TEXT_VIEW; }
"ImageView" { return IMAGE_VIEW; }
"Button" { return BUTTON; }
"RadioGroup" { return RADIO_GROUP; }
"RadioButton" { return RADIO_BUTTON; }
"ProgressBar" { return PROGRESS_BAR; }

"android:layout_width" { return LAYOUT_WIDTH; }
"android:layout_height" { return LAYOUT_HEIGHT; }
"android:orientation" { return ORIENTATION; }
"android:id" { return ID; }
"android:text" { return TEXT; }
"android:textColor" { return TEXT_COLOR; }
"android:src" { return SRC; }
"android:padding" { return PADDING; }
"android:checkedButton" { return CHECKED_BUTTON; }
"android:max" { return MAX; }
"android:progress" { return PROGRESS; }

"android:radioCount" { return RADIO_COUNT; }

"=" { return EQUALS; }
{DIGIT}+ { yylval.ival = atoi(yytext); return POS_INT_VALUE; }

"match_parent" { yylval.sval = strdup(yytext); return ALPHANUM_VALUE; }
"wrap_content" { yylval.sval = strdup(yytext); return ALPHANUM_VALUE; }
\"{ALPHANUM}+\" { 
  yytext[strlen(yytext)-1] = 0;
  yylval.sval = strdup(yytext+1); 
  return ALPHANUM_VALUE; 
}

\"{STRING}\" { yylval.sval = strdup(yytext); return ALPHANUM_VALUE; }

[ \t\n]  { /* ignore whitespace */ }

. { fprintf(stderr, "Syntax Error: Unknown character: %s at line %d\n", yytext, yylineno); exit(1); }


%%

int yywrap() {
    return 1;
}
