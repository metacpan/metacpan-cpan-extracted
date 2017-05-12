#include <list>
#include <string>
#include <cstdio>
#include "logical_expression_parser/logical_expression_parser_includes.h"
#include <iostream>

using namespace std;

extern FILE *logical_expression_parser_in;
extern int logical_expression_parser_parse();
extern void logical_expression_parser_parser_initialize();
extern list<string> parsed_expressions;

int main(int argc, char *argv[]) {
  if (argc != 2)
  {
    cout << "Please provide the file to parse" << endl;
    return 1;
  }

  logical_expression_parser_in = fopen(argv[1], "r");
  logical_expression_parser_parser_initialize();
  logical_expression_parser_parse();
  fclose(logical_expression_parser_in);

  list<string>::const_iterator a_wfe;
  for (a_wfe = parsed_expressions.begin();
       a_wfe != parsed_expressions.end();
       a_wfe++)
  {
    cout << "Parsed: " << *a_wfe << endl;
  }

  if (parsed_expressions.size() > 0)
    return 0;
  else
    return 1;
}
