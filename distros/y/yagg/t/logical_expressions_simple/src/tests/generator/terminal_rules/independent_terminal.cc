#include <iostream>
#include <sstream>
#include <cassert>

using namespace std;

#include "generator/utility/to_string.h"
#include "generator/rule_list/rule_list.h"
#include "generator/rule/terminal_rule.h"

class NATURAL : public Terminal_Rule
{
public:
  virtual const bool Check_For_String();
  virtual const list<string>& Get_String() const;
  virtual const unsigned long int& Get_Value();

protected:
  list<string> strings;
  unsigned long int return_value;
};

// ---------------------------------------------------------------------------

const bool NATURAL::Check_For_String()
{
  if (!Is_Valid())
    return false;

  m_string_count++;

  if (m_string_count > 3)
    return false;

  switch (m_string_count)
  {
    case 1 :
    {
      return_value = 1;
      break;
    }
    case 2 :
    {
      return_value = 15;
      break;
    }
    case 3 :
    {
      return_value = 20;
      break;
    }

  }

  strings.clear();

  stringstream temp_stream;
  temp_stream << return_value;

  strings.push_back(temp_stream.str());

  return true;
}

// ---------------------------------------------------------------------------

const list<string>& NATURAL::Get_String() const
{
  assert(m_string_count <= 3);

  return strings;
}

// ---------------------------------------------------------------------------

const unsigned long int& NATURAL::Get_Value()
{
  Set_Accessed(true);

  return return_value;
}

// ---------------------------------------------------------------------------

int main(int argc, char *argv[])
{
  list< list< string > > results;

  {
    Rule_List start;

    start.push_back(new NATURAL);
    start.push_back(new NATURAL);
    start.push_back(new NATURAL);

    start.Initialize(3);

    while(start.Check_For_String())
    {
      results.push_back( start.Get_String() );
    }
  }

  bool error = false;

  list< list< string > > expected_results;

  {
    list<string> temp_string_list;
    temp_string_list.push_back("1");
    temp_string_list.push_back("1");
    temp_string_list.push_back("1");
    expected_results.push_back(temp_string_list);
  }

  {
    list<string> temp_string_list;
    temp_string_list.push_back("1");
    temp_string_list.push_back("1");
    temp_string_list.push_back("15");
    expected_results.push_back(temp_string_list);
  }

  {
    list<string> temp_string_list;
    temp_string_list.push_back("1");
    temp_string_list.push_back("1");
    temp_string_list.push_back("20");
    expected_results.push_back(temp_string_list);
  }

  {
    list<string> temp_string_list;
    temp_string_list.push_back("1");
    temp_string_list.push_back("15");
    temp_string_list.push_back("1");
    expected_results.push_back(temp_string_list);
  }

  {
    list<string> temp_string_list;
    temp_string_list.push_back("1");
    temp_string_list.push_back("15");
    temp_string_list.push_back("15");
    expected_results.push_back(temp_string_list);
  }

  {
    list<string> temp_string_list;
    temp_string_list.push_back("1");
    temp_string_list.push_back("15");
    temp_string_list.push_back("20");
    expected_results.push_back(temp_string_list);
  }

  {
    list<string> temp_string_list;
    temp_string_list.push_back("1");
    temp_string_list.push_back("20");
    temp_string_list.push_back("1");
    expected_results.push_back(temp_string_list);
  }

  {
    list<string> temp_string_list;
    temp_string_list.push_back("1");
    temp_string_list.push_back("20");
    temp_string_list.push_back("15");
    expected_results.push_back(temp_string_list);
  }

  {
    list<string> temp_string_list;
    temp_string_list.push_back("1");
    temp_string_list.push_back("20");
    temp_string_list.push_back("20");
    expected_results.push_back(temp_string_list);
  }

  {
    list<string> temp_string_list;
    temp_string_list.push_back("15");
    temp_string_list.push_back("1");
    temp_string_list.push_back("1");
    expected_results.push_back(temp_string_list);
  }

  {
    list<string> temp_string_list;
    temp_string_list.push_back("15");
    temp_string_list.push_back("1");
    temp_string_list.push_back("15");
    expected_results.push_back(temp_string_list);
  }

  {
    list<string> temp_string_list;
    temp_string_list.push_back("15");
    temp_string_list.push_back("1");
    temp_string_list.push_back("20");
    expected_results.push_back(temp_string_list);
  }

  {
    list<string> temp_string_list;
    temp_string_list.push_back("15");
    temp_string_list.push_back("15");
    temp_string_list.push_back("1");
    expected_results.push_back(temp_string_list);
  }

  {
    list<string> temp_string_list;
    temp_string_list.push_back("15");
    temp_string_list.push_back("15");
    temp_string_list.push_back("15");
    expected_results.push_back(temp_string_list);
  }

  {
    list<string> temp_string_list;
    temp_string_list.push_back("15");
    temp_string_list.push_back("15");
    temp_string_list.push_back("20");
    expected_results.push_back(temp_string_list);
  }

  {
    list<string> temp_string_list;
    temp_string_list.push_back("15");
    temp_string_list.push_back("20");
    temp_string_list.push_back("1");
    expected_results.push_back(temp_string_list);
  }

  {
    list<string> temp_string_list;
    temp_string_list.push_back("15");
    temp_string_list.push_back("20");
    temp_string_list.push_back("15");
    expected_results.push_back(temp_string_list);
  }

  {
    list<string> temp_string_list;
    temp_string_list.push_back("15");
    temp_string_list.push_back("20");
    temp_string_list.push_back("20");
    expected_results.push_back(temp_string_list);
  }

  {
    list<string> temp_string_list;
    temp_string_list.push_back("20");
    temp_string_list.push_back("1");
    temp_string_list.push_back("1");
    expected_results.push_back(temp_string_list);
  }

  {
    list<string> temp_string_list;
    temp_string_list.push_back("20");
    temp_string_list.push_back("1");
    temp_string_list.push_back("15");
    expected_results.push_back(temp_string_list);
  }

  {
    list<string> temp_string_list;
    temp_string_list.push_back("20");
    temp_string_list.push_back("1");
    temp_string_list.push_back("20");
    expected_results.push_back(temp_string_list);
  }

  {
    list<string> temp_string_list;
    temp_string_list.push_back("20");
    temp_string_list.push_back("15");
    temp_string_list.push_back("1");
    expected_results.push_back(temp_string_list);
  }

  {
    list<string> temp_string_list;
    temp_string_list.push_back("20");
    temp_string_list.push_back("15");
    temp_string_list.push_back("15");
    expected_results.push_back(temp_string_list);
  }

  {
    list<string> temp_string_list;
    temp_string_list.push_back("20");
    temp_string_list.push_back("15");
    temp_string_list.push_back("20");
    expected_results.push_back(temp_string_list);
  }

  {
    list<string> temp_string_list;
    temp_string_list.push_back("20");
    temp_string_list.push_back("20");
    temp_string_list.push_back("1");
    expected_results.push_back(temp_string_list);
  }

  {
    list<string> temp_string_list;
    temp_string_list.push_back("20");
    temp_string_list.push_back("20");
    temp_string_list.push_back("15");
    expected_results.push_back(temp_string_list);
  }

  {
    list<string> temp_string_list;
    temp_string_list.push_back("20");
    temp_string_list.push_back("20");
    temp_string_list.push_back("20");
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
