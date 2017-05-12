#include <iostream>
#include <sstream>
#include <map>
#include <string>
#include "model/nonterminal_rules/wfe.h"
#include "model/terminal_rules/ATOMIC.h"
#include "model/terminal_rules/BINARY_OPERATOR.h"
#include "model/terminal_rules/LEFT_PAREN.h"
#include "model/terminal_rules/RIGHT_PAREN.h"
#include "model/terminal_rules/UNARY_OPERATOR.h"

using namespace std;

string chosen_rule;
map<string, Rule*> name_to_rule;

// ---------------------------------------------------------------------------

void Print_Strings(ostream &in_stream, Rule* in_rule)
{
  const list<string> start_string_list = in_rule->Get_String();
  bool need_space = false;

  in_stream << "--" << endl;

  list<string>::const_iterator a_string;
  for (a_string = start_string_list.begin();
       a_string != start_string_list.end();
       a_string++)
  {
    if(need_space)
      in_stream << " ";
    else
      need_space = true;

    in_stream << *a_string;

    if (a_string->size() > 0 && a_string->substr(a_string->size()-1,1) == "\n")
      need_space = false;
  }

  in_stream << endl;
}

// ---------------------------------------------------------------------------

int main(int argc, char *argv[])
{
  if (argc != 2 && argc != 3)
  {
    cerr << "Usage: generate [rule name] <length>\n";
    return 1;
  }

  name_to_rule["wfe"] = new wfe();
  name_to_rule["ATOMIC"] = new ATOMIC();
  name_to_rule["BINARY_OPERATOR"] = new BINARY_OPERATOR();
  name_to_rule["LEFT_PAREN"] = new LEFT_PAREN();
  name_to_rule["RIGHT_PAREN"] = new RIGHT_PAREN();
  name_to_rule["UNARY_OPERATOR"] = new UNARY_OPERATOR();

  map<string, unsigned int> name_to_minimum_length;
  name_to_minimum_length["wfe"] = 1;
  name_to_minimum_length["ATOMIC"] = 1;
  name_to_minimum_length["BINARY_OPERATOR"] = 1;
  name_to_minimum_length["LEFT_PAREN"] = 1;
  name_to_minimum_length["RIGHT_PAREN"] = 1;
  name_to_minimum_length["UNARY_OPERATOR"] = 1;

  unsigned int allowed_length;

  if (argc == 2)
  {
    chosen_rule = "wfe";
    istringstream number_string(argv[1]);
    number_string >> allowed_length;
  }
  else
  {
    istringstream name_string(argv[1]);
    name_string >> chosen_rule;
    istringstream number_string(argv[2]);
    number_string >> allowed_length;
  }


  if (allowed_length < name_to_minimum_length[chosen_rule])
  {
    cerr << "You must provide a number greater than or equal to " <<
      name_to_minimum_length[chosen_rule] << endl;

    map<string, Rule*>::iterator a_rule;
    for (a_rule = name_to_rule.begin(); a_rule != name_to_rule.end(); a_rule++)
      delete a_rule->second;

    return 1;
  }

  cout << "Initializing grammar..." << endl;

  name_to_rule[chosen_rule]->Initialize(allowed_length);

  cout << "Generating strings..." << endl;

  while(name_to_rule[chosen_rule]->Check_For_String())
  {
#ifdef SHORT_RULE_TRACE
    Print_Strings(cerr,name_to_rule[chosen_rule]);
#endif // SHORT_RULE_TRACE
    Print_Strings(cout,name_to_rule[chosen_rule]);
  }

  map<string, Rule*>::iterator a_rule;
  for (a_rule = name_to_rule.begin(); a_rule != name_to_rule.end(); a_rule++)
    delete a_rule->second;

  return 0;
}
