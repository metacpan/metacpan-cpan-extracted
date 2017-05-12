%{
#include <string>
#include <list>
#include "logical_expression_parser/logical_expression_parser_includes.h"
#include "logical_expression_parser/logical_expression_parser.h"
#include <iostream>
#include <sstream>

using namespace std;

// -----------------------------------------------------------------

void logical_expression_parser_error (string s);
string logical_expression_parser_error_string;

bool logical_expression_parser_reached_end_of_file;
%}

/* Track line number */
%option yylineno

/* Make a case-insensitive scanner. */
%option case-insensitive

/* Set the name prefix so we can have multiple lexers in the same program. */
%option prefix="logical_expression_parser_"

/* Just have yywrap return 1. */
%option noyywrap

/* Necessary for Windows, because there is no isatty function, which is
 * generated for interactive execution. */
%option    never-interactive

%s quoted

%%

[ \t]+ {
}

"(" {
  return LEFT_PAREN;
}

")" {
  return RIGHT_PAREN;
}

"\n" {
  return NEWLINE;
}

(<=>|and|or|=>) {
  logical_expression_parser_lval.text = new string(logical_expression_parser_text);
  return BINARY_OPERATOR;
}

[a-zA-Z]+ {
  logical_expression_parser_lval.text = new string(logical_expression_parser_text);
  return ATOMIC;
}

- {
  return UNARY_OPERATOR;
}

%%

void logical_expression_parser_error(string error_string)
{
  ostringstream temp_string;
  temp_string << logical_expression_parser_lineno;

  // Generic yacc "syntax error" message isn't very useful
  if (error_string != "syntax error")
//    logical_expression_parser_error_string += "SYNTAX ERROR (line " + temp_string.str() +
//      "): " + error_string + "\n";
    cerr << "SYNTAX ERROR (line " + temp_string.str() +
      "): " + error_string + "\n";
  else
//    logical_expression_parser_error_string += "SYNTAX ERROR (line " + temp_string.str() +
//      ")\n";
    cerr << "SYNTAX ERROR (line " + temp_string.str() +
      ")\n";
}

void logical_expression_parser_scanner_initialize()
{
  logical_expression_parser_error_string = "";
}
