#include <iostream>
#include <sstream>

using namespace std;

#include "generator/utility/utility.h"
#include "generator/rule_list/rule_list.h"
#include "generator/rule/terminal_rule.h"

// ---------------------------------------------------------------------------

class ZERO : public Terminal_Rule
{
public:
  ZERO();

  virtual const list<string>& Get_String() const;
  virtual const string& Get_Value();

protected:
  list<string> strings;
  string return_value;
};

// ---------------------------------------------------------------------------

ZERO::ZERO()
{
  return_value = "zero";

  strings.clear();

  strings.push_back(return_value);
}

// ---------------------------------------------------------------------------

const list<string>& ZERO::Get_String() const
{
  return strings;
}

// ---------------------------------------------------------------------------

const string& ZERO::Get_Value()
{
  Set_Accessed(true);

  return return_value;
}

// ---------------------------------------------------------------------------

int main(int argc, char *argv[])
{
  list< list< string > > results;

  {
    ZERO start;

    start.Initialize(1);

    while(start.Check_For_String())
      results.push_back( start.Get_String() );
  }

  bool error = false;

  list< list< string > > expected_results;
  list<string> temp_string_list;

  temp_string_list.push_back("zero");
  expected_results.push_back(temp_string_list);

  if (expected_results != results)
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
