#include <iostream>
#include <sstream>

using namespace std;

#include "generator/utility/utility.h"
#include "generator/rule/nonterminal_rule.h"
#include "generator/rule/terminal_rule.h"
#include "model/nonterminal_rules/identifier_list.h"

// ---------------------------------------------------------------------------

int main(int argc, char *argv[])
{
  list< list< string > > results;

  {
    identifier_list start;

    start.Initialize(3);

    while(start.Check_For_String())
    {
      list<string> generated_string = start.Get_String();
//      cout << "GENERATED STRING: " <<
//        Utility::to_string(generated_string.begin(),generated_string.end()) << endl;
      results.push_back( generated_string );
    }
  }

  bool error = false;

  list< list< string > > expected_results;

  {
    list<string> temp_string_list;
    temp_string_list.push_back("id_1");
    temp_string_list.push_back("id_2");
    temp_string_list.push_back("id_3");
    expected_results.push_back(temp_string_list);
  }

  if(results != expected_results)
  {
    cout << "Lists do not match" << endl;

    {
      cout << endl << "Expected:" << endl;
      list< list<string> >::const_iterator a_list;
      for(a_list = expected_results.begin();
          a_list != expected_results.end();
          a_list++)
      {
        cout << Utility::to_string((*a_list).begin(), (*a_list).end());
      }
    }

    {
      cout << endl << "Actual:" << endl;
      list< list<string> >::const_iterator a_list;
      for(a_list = results.begin();
          a_list != results.end();
          a_list++)
      {
        cout << Utility::to_string((*a_list).begin(), (*a_list).end());
      }
    }

    error = true;
  }
  else
  {
    cout << "Lists match" << endl;
  }

  if (error)
    return 1;
  else
    return 0;
}
