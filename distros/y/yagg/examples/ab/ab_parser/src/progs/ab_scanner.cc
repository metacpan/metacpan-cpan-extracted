#include <string>
#include <cstdio>
#include <iostream>

using namespace std;

extern FILE *ab_parser_in;
extern int ab_parser_lex();
extern char *ab_parser_text;

int main(int argc, char *argv[]) {
  ab_parser_in = fopen(argv[1], "r");

  while (ab_parser_lex())
  {
    if ((string)ab_parser_text == (string)"\n")
      cout << "Scanned: <NEWLINE>" << endl;
    else
      cout << "Scanned: " << ab_parser_text << endl;
  }

  fclose(ab_parser_in);

  return 0;
}

