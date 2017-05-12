#include <iostream>
#include <sstream>
#include <map>
#include <string>
[[[
foreach my $rule (@{$grammar->{'NONTERMINALS'}})
{
  $OUT .= qq{#include "model/nonterminal_rules/$rule.h"\n};
}
foreach my $rule (@{$grammar->{'TERMINALS'}})
{
  $OUT .= qq{#include "model/terminal_rules/$rule.h"\n};
}

chomp $OUT;
]]]

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

[[[
foreach my $rule (@{$grammar->{'NONTERMINALS'}})
{
  $OUT .= qq{  name_to_rule["$rule"] = new $rule();\n};
}
foreach my $rule (@{$grammar->{'TERMINALS'}})
{
  $OUT .= qq{  name_to_rule["$rule"] = new $rule();\n};
}
]]]
  map<string, unsigned int> name_to_minimum_length;
[[[
foreach my $rule (@{$grammar->{'NONTERMINALS'}})
{
  $OUT .= qq{  name_to_minimum_length["$rule"] = $minimum_lengths{$rule};\n};
}
foreach my $rule (@{$grammar->{'TERMINALS'}})
{
  $OUT .= qq{  name_to_minimum_length["$rule"] = 1;\n};
}
]]]
  unsigned int allowed_length;

  if (argc == 2)
  {
    chosen_rule = "[[[$starting_rule]]]";
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
