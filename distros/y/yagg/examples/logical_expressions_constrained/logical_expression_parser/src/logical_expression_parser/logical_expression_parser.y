%{
#include <string>
#include <list>
#include "logical_expression_parser/logical_expression_parser_includes.h"
#include <iostream>

using namespace std;

list<string> parsed_expressions;

bool error_mode = false;
%}

%union {
  string*       text;
  list<string>* text_list;
  float*        number;
}

%type     <text_list>            wfe
%left     <text>                 BINARY_OPERATOR
%token    <text>                 ATOMIC
%nonassoc                        UNARY_OPERATOR
%token                           LEFT_PAREN
%token                           RIGHT_PAREN
%token                           NEWLINE

%% 

wfe_nonterminal :
  wfe NEWLINE {
    if (!error_mode)
    {
      string joined;

      list<string>::const_iterator a_string;
      for (a_string = $1->begin(); a_string != $1->end(); a_string++)
      {
        joined += *a_string + " ";
      }

      parsed_expressions.push_back(joined);
    }

    delete $1;
  } ;

wfe :
  wfe BINARY_OPERATOR wfe
  {
    if ($1->back() == $3->front())
    {
      logical_expression_parser_error("Binary expression \"" + $1->back() +
        " " + *$2 + " " + $3->front() + "\" has the same atomics.");

      // There's probably a better way to skip to the next definition
      error_mode = true;
      delete $1;
    }
    else
    {
      $$ = $1;
      $$->push_back(*$2);

      $$->insert($$->end(),$3->begin(),$3->end());
    }

    delete $2;
    delete $3;
  }
  |
  LEFT_PAREN wfe RIGHT_PAREN
  {
    $$ = $2;
    $$->push_front("(");
    $$->push_back(")");
  }
  |
  UNARY_OPERATOR wfe
  {
    $$ = $2;
    $$->push_front("-");
  }
  |
  ATOMIC
  {
    $$ = new list<string>;
    $$->push_back(*$1);

    delete $1;
  }
  |
  /* Try to go on to the next definition if we hit an error */
  error NEWLINE ;

/* ----------------------------------------------------------------- */

%% 

extern int logical_expression_parser_lineno;
extern int logical_expression_parser_lex();

extern void logical_expression_parser_error(string s);
extern void logical_expression_parser_scanner_initialize();

void logical_expression_parser_parser_initialize()
{
  logical_expression_parser_scanner_initialize();
  error_mode = false;

  logical_expression_parser_lineno = 1;
}
