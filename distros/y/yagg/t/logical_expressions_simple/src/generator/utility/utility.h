#ifndef UTILITY_H
#define UTILITY_H

#include <string>

using namespace std;

#include "to_string.h"

class Rule_List;

namespace Utility
{

extern string indent;

void Indent();

void Unindent();

string to_string(const Rule_List &in_rule_list, const bool &in_show_lengths = true);

string readable_type_name(type_info const& typeinfo);

void yyerror();

}

#endif // UTILITY_H
