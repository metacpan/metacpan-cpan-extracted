// Include some declarations that we need
%{
#include <list>
#include <string>
#include "ab_parser/ab_parser_includes.h"

using namespace std;

list<string> parsed_strings;
%}

// Define the return types
%union {
  list<string>* text_list;
  string*       text;
}

// Define the grammar production return types
%type <text_list> node_list
%type <text>      node
%token            A
%token            B
%token            NEWLINE

%%

node_list_nonterminal :
  node_list NEWLINE {
    string joined;

    list<string>::const_iterator a_string;
    for (a_string = $1->begin(); a_string != $1->end(); a_string++)
    {
      joined += *a_string + " ";
    }

    parsed_strings.push_back(joined);

    delete $1;
  } ;

node_list :
  node_list node
  {
    if ($1->size() > 0 && $1->back() == "b" && *$2 == "a")
    {
      yyerror("\"a\" can't follow \"b\"! Ignoring...");

      $$ = $1;
    }
    else
    {
      $$ = $1;
      $$->push_back(*$2);
    }

    delete $2;
  } |
  node
  {
    $$ = new list<string>;
    $$->push_back(*$1);

    delete $1;
  };

node :
  A { $$ = new string("a"); } |
  B { $$ = new string("b"); } ;

/* ----------------------------------------------------------------- */

%% 

extern int ab_parser_lineno;
extern int ab_parser_lex();

extern void ab_parser_error(string s);
extern void ab_parser_scanner_initialize();

void ab_parser_parser_initialize()
{
  ab_parser_scanner_initialize();

  ab_parser_lineno = 1;
}

