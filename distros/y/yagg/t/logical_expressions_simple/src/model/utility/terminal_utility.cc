#include "model/utility/terminal_utility.h"
#include "generator/utility/utility.h"

int yylineno = 0;

void yyrestart(FILE* in_input_file)
{
}

void yyerror(string error_string)
{
  Utility::yyerror();
}



