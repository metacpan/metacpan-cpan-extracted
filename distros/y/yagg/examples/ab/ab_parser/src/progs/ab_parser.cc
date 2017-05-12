#include <list>
#include <string>
#include <cstdio>
#include "ab_parser/ab_parser_includes.h"
#include <iostream>

using namespace std;

extern FILE *ab_parser_in;
extern int ab_parser_parse();
extern void ab_parser_parser_initialize();
extern list<string> parsed_strings;

int main(int argc, char *argv[]) {
  if (argc != 2)
  {
    cout << "Please provide the file to parse" << endl;
    return 1;
  }

  ab_parser_in = fopen(argv[1], "r");
  ab_parser_parser_initialize();
  ab_parser_parse();
  fclose(ab_parser_in);

  list<string>::const_iterator a_wfe;
  for (a_wfe = parsed_strings.begin();
       a_wfe != parsed_strings.end();
       a_wfe++)
  {
    cout << "Parsed: " << *a_wfe << endl;
  }

  if (parsed_strings.size() > 0)
    return 0;
  else
    return 1;
}
