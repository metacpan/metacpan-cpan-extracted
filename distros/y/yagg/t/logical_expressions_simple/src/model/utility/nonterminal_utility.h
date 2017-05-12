#ifndef nonterminal_utility_h
#define nonterminal_utility_h



#include <string>
#include <cstdio>

using namespace std;

const int yyATOMIC = 257;
const int yyBINARY_OPERATOR = 258;
const int yyLEFT_PAREN = 259;
const int yyRIGHT_PAREN = 260;
const int yyUNARY_OPERATOR = 261;

extern int yylineno;
extern void yyrestart(FILE* in_input_file);
extern void yyerror(string error_string);


#endif // nonterminal_utility_h
