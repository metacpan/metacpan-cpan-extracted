#include <string>
#include <cstdio>
#include <iostream>

using namespace std;

extern FILE *logical_expression_parser_in;
extern int logical_expression_parser_lex();
extern char *logical_expression_parser_text;

int main(int argc, char *argv[]) {
  logical_expression_parser_in = fopen(argv[1], "r");

  while (logical_expression_parser_lex())
  {
    if ((string)logical_expression_parser_text == (string)"\n")
      cout << "Scanned: <NEWLINE>" << endl;
    else
      cout << "Scanned: " << logical_expression_parser_text << endl;
  }

  fclose(logical_expression_parser_in);

  return 0;
}

