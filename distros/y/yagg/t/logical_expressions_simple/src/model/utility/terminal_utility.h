#ifndef terminal_utility_h
#define terminal_utility_h



#include <string>
#include <cstdio>

using namespace std;


extern int yylineno;
extern void yyrestart(FILE* in_input_file);
extern void yyerror(string error_string);


#endif // terminal_utility_h
