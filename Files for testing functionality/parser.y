%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "parser.tab.h"
extern FILE *yyin;
extern int yylineno;
int yylex(void);
void yyerror(const char *s);
void validate_radio_group();
void validate_layout(char *value);
void validate_padding(char *value);


#define MAX_IDS 100
char* ids[MAX_IDS];
int ids_len = 0;

int id_exists(char *id) {
  for (int i = 0; i < ids_len; i++) {
    if (strcmp(ids[i], id) == 0) {
      return 1;
    }
  }
  return 0;
}

void add_id(char *id) {
  if (ids_len >= MAX_IDS) {
    fprintf(stderr, "Too many ids\n");
    exit(1);
  }
  if (id_exists(id)) {
    fprintf(stderr, "Duplicate id: %s\n", id);
    exit(1);
  }
  ids[ids_len++] = id;
}

char* checkedButtonId = NULL;

void validate_checked_button() {
  if (checkedButtonId != NULL && !id_exists(checkedButtonId)) {
    fprintf(stderr, "Invalid checkedButton id: %s\n", checkedButtonId);
    exit(1);
  }
  checkedButtonId = NULL;
}

int max = -1;
int progress = -1;

void validate_progress() {
  if (progress != -1 && max != -1 && (progress < 0 || progress > max)) {
    fprintf(stderr, "Invalid progress value: %d. It must be between 0 and max value (%d).\n", progress, max);
    exit(1);
  }
  max = -1;
  progress = -1;
}

int expectedRadioButtonCount = -1;
int radioButtonCount = 0;


%}

%union {
  int ival;
  char *sval;
}

%define parse.trace
%define parse.error verbose

%token <ival> POS_INT_VALUE
%token <sval> ALPHANUM_VALUE

%token OPEN_ANGLE CLOSE_ANGLE SLASH EQUALS

%token LINEAR_LAYOUT RELATIVE_LAYOUT TEXT_VIEW IMAGE_VIEW BUTTON RADIO_GROUP RADIO_BUTTON PROGRESS_BAR
%token LAYOUT_WIDTH LAYOUT_HEIGHT ORIENTATION ID TEXT TEXT_COLOR SRC PADDING CHECKED_BUTTON MAX PROGRESS
%token STRING

%token RADIO_COUNT

%%

start: 
  root_elements
;

root_elements:
  linear_layout
| relative_layout
;

elements:
  | elements element
;

element:
  linear_layout
| relative_layout
| text_view
| image_view
| button
| radio_group
| radio_button
| progress_bar
;

linear_layout: OPEN_ANGLE LINEAR_LAYOUT attributes CLOSE_ANGLE elements OPEN_ANGLE SLASH LINEAR_LAYOUT CLOSE_ANGLE;

relative_layout: OPEN_ANGLE RELATIVE_LAYOUT attributes CLOSE_ANGLE elements OPEN_ANGLE SLASH RELATIVE_LAYOUT CLOSE_ANGLE;

text_view: OPEN_ANGLE TEXT_VIEW attributes SLASH CLOSE_ANGLE;

image_view: OPEN_ANGLE IMAGE_VIEW attributes SLASH CLOSE_ANGLE;

button: OPEN_ANGLE BUTTON attributes SLASH CLOSE_ANGLE;

radio_group: OPEN_ANGLE RADIO_GROUP attributes CLOSE_ANGLE elements OPEN_ANGLE SLASH RADIO_GROUP CLOSE_ANGLE { validate_checked_button(); validate_radio_group(); };



radio_button: OPEN_ANGLE RADIO_BUTTON attributes SLASH CLOSE_ANGLE { radioButtonCount++; };

progress_bar: OPEN_ANGLE PROGRESS_BAR attributes SLASH CLOSE_ANGLE { validate_progress(); };


attributes:
  | attributes attribute
;

attribute:
  LAYOUT_WIDTH EQUALS ALPHANUM_VALUE { validate_layout($3); }
| LAYOUT_HEIGHT EQUALS ALPHANUM_VALUE { validate_layout($3); }
| ORIENTATION EQUALS ALPHANUM_VALUE
| ID EQUALS ALPHANUM_VALUE { add_id($3); }
| TEXT EQUALS ALPHANUM_VALUE
| TEXT_COLOR EQUALS ALPHANUM_VALUE
| SRC EQUALS ALPHANUM_VALUE
| PADDING EQUALS ALPHANUM_VALUE { validate_padding($3); } 
| CHECKED_BUTTON EQUALS ALPHANUM_VALUE { checkedButtonId = strdup($3); }
| MAX EQUALS ALPHANUM_VALUE { max = atoi($3); }
| PROGRESS EQUALS ALPHANUM_VALUE { progress = atoi($3); validate_progress(); }
| RADIO_COUNT EQUALS ALPHANUM_VALUE { expectedRadioButtonCount = atoi($3); }
;



%%

void validate_radio_group() {
  if (expectedRadioButtonCount != -1 && radioButtonCount != expectedRadioButtonCount) {
    fprintf(stderr, "Invalid number of RadioButton elements: %d. Expected %d.\n", radioButtonCount, expectedRadioButtonCount);
    exit(1);
  }
  expectedRadioButtonCount = -1;
  radioButtonCount = 0;
}

void validate_padding(char *value) {
  char *endptr;
  long padding_value = strtol(value, &endptr, 10);
  if (*endptr != '\0' || padding_value <= 0) {
    fprintf(stderr, "Invalid value for padding: %s\n", value);
    exit(1);
  }
}

void validate_layout(char *value) {
  if (strcmp(value, "wrap_content") != 0 && strcmp(value, "match_parent") != 0) {
    char *endptr;
    long width_height_value = strtol(value, &endptr, 10);
    if (*endptr != '\0' || width_height_value <= 0) {
      fprintf(stderr, "Invalid value for layout_width or layout_height: %s\n", value);
      exit(1);
    }
  }
}

void yyerror(const char *s) {
  fprintf(stderr, "Parse error at line %d: %s\n", yylineno, s);
  exit(1);
}


int main(int argc, char **argv) {
  if (argc > 1) {
    FILE *file = fopen(argv[1], "r");
    if (!file) {
      fprintf(stderr, "Unable to open file %s\n", argv[1]);
      return 1;
    }
    yyin = file;
  }
  yyparse();
  printf("Parsing completed successfully.\n");
  return 0;
}
