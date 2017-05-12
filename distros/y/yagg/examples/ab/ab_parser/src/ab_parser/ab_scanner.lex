%{
#include <string>
#include <list>
#include "ab_parser/ab_parser_includes.h"
#include "ab_parser/ab_parser.h"
#include <iostream>
#include <sstream>

using namespace std;

// -----------------------------------------------------------------

void ab_parser_error (string s);
string ab_parser_error_string;

bool ab_parser_reached_end_of_file;
%}

/* Track line number */
%option yylineno

/* Make a case-insensitive scanner. */
%option case-insensitive

/* Set the name prefix so we can have multiple lexers in the same program. */
%option prefix="ab_parser_"

/* Just have yywrap return 1. */
%option noyywrap

/* Necessary for Windows, because there is no isatty function, which is
 * generated for interactive execution. */
%option    never-interactive

%s quoted

%%

[ \t]+ {
}

"a" {
  return A;
}

"b" {
  return B;
}

"\n" {
  return NEWLINE;
}

%%

void ab_parser_error(string error_string)
{
  ostringstream temp_string;
  temp_string << ab_parser_lineno;

  // Generic yacc "syntax error" message isn't very useful
  if (error_string != "syntax error")
//    ab_parser_error_string += "SYNTAX ERROR (line " + temp_string.str() +
//      "): " + error_string + "\n";
    cerr << "SYNTAX ERROR (line " + temp_string.str() +
      "): " + error_string + "\n";
  else
//    ab_parser_error_string += "SYNTAX ERROR (line " + temp_string.str() +
//      ")\n";
    cerr << "SYNTAX ERROR (line " + temp_string.str() +
      ")\n";
}

void ab_parser_scanner_initialize()
{
  ab_parser_error_string = "";
}
