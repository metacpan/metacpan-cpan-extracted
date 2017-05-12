#include <iostream>
#include <sstream>

using namespace std;

#include "generator/utility/utility.h"
#include "generator/rule_list/rule_list.h"
#include "generator/rule/nonterminal_rule.h"
#include "generator/rule/terminal_rule.h"

// ---------------------------------------------------------------------------

class IDENTIFIER : public Terminal_Rule
{
public:
  virtual const bool Check_For_String();
  virtual const list<string>& Get_String() const;
  virtual const string* Get_Value();

protected:
  list<string> strings;
  string return_value;
};

// ---------------------------------------------------------------------------

const bool IDENTIFIER::Check_For_String()
{
  if (!Is_Valid())
    return false;

  static map<unsigned int, unsigned int> counts;

  if (counts.find(m_string_count) != counts.end())
  {
    if (counts[m_string_count] == 1)
      counts.erase(m_string_count);
    else
      counts[m_string_count]--;
  }

  m_string_count++;

  if (m_string_count > counts.size() + 1)
    return false;

  counts[m_string_count]++;

  stringstream temp_stream;

  temp_stream << "id_" << m_string_count;
  return_value = temp_stream.str();

  strings.clear();

  strings.push_back(return_value);

  return true;
}

// ---------------------------------------------------------------------------

const list<string>& IDENTIFIER::Get_String() const
{
  return strings;
}

// ---------------------------------------------------------------------------

const string* IDENTIFIER::Get_Value()
{
  Set_Accessed(true);

  return &return_value;
}

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------

class identifier_list : public Nonterminal_Rule
{
public:
  virtual void Initialize(const unsigned int in_allowed_length, const Rule *in_previous_rule);

};

// ---------------------------------------------------------------------------

void identifier_list::Initialize(const unsigned int in_allowed_length, const Rule *in_previous_rule = NULL)
{
  list<Rule_List*>::iterator a_rule_list;
  for(a_rule_list = m_rule_lists.begin();
      a_rule_list != m_rule_lists.end();
      a_rule_list++)
    delete *a_rule_list;

  m_rule_lists.clear();

  {
    Rule_List* rule_list = new Rule_List;

    rule_list->push_back(new IDENTIFIER);
    rule_list->push_back(new IDENTIFIER);
    rule_list->push_back(new IDENTIFIER);

    m_rule_lists.push_back(rule_list);
  }

  Nonterminal_Rule::Initialize(in_allowed_length,in_previous_rule);
}

// ---------------------------------------------------------------------------

int main(int argc, char *argv[])
{
  list< list< string > > results;

  {
    identifier_list start;

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
    temp_string_list.push_back("id_1");
    temp_string_list.push_back("id_1");
    temp_string_list.push_back("id_1");
    expected_results.push_back(temp_string_list);
  }

  {
    list<string> temp_string_list;
    temp_string_list.push_back("id_1");
    temp_string_list.push_back("id_1");
    temp_string_list.push_back("id_2");
    expected_results.push_back(temp_string_list);
  }

  {
    list<string> temp_string_list;
    temp_string_list.push_back("id_1");
    temp_string_list.push_back("id_2");
    temp_string_list.push_back("id_1");
    expected_results.push_back(temp_string_list);
  }

  {
    list<string> temp_string_list;
    temp_string_list.push_back("id_1");
    temp_string_list.push_back("id_2");
    temp_string_list.push_back("id_2");
    expected_results.push_back(temp_string_list);
  }

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
