#include <iostream>
#include <sstream>

using namespace std;

#include "model/utility/nonterminal_utility.h"
#include "generator/rule/nonterminal_rule.h"
#include "generator/rule/terminal_rule.h"

// ---------------------------------------------------------------------------

class IDENTIFIER : public Terminal_Rule
{
public:
  virtual const bool Check_For_String();
  virtual const list<string>& Get_String() const;
  virtual const string& Get_Value();

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

const string& IDENTIFIER::Get_Value()
{
  Set_Accessed(true);

  return return_value;
}

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------

class identifier_list : public Nonterminal_Rule
{
  class match_1;
  class match_2;

public:
  identifier_list();
  virtual ~identifier_list();

  virtual void Initialize(const unsigned int in_allowed_length, const Rule *in_previous_rule = NULL);

protected:
  match_1 *m_1;
  match_2 *m_2;
};

// ---------------------------------------------------------------------------

class identifier_list::match_1 : public Rule_List
{
  friend class identifier_list;

  match_1()
  {
    push_back(new IDENTIFIER);
  }

};

// ---------------------------------------------------------------------------

class identifier_list::match_2 : public Rule_List
{
  friend class identifier_list;

  match_2()
  {
    push_back(new identifier_list);
    push_back(new IDENTIFIER);
  }

};

// ---------------------------------------------------------------------------

identifier_list::identifier_list() : Nonterminal_Rule()
{
  m_1 = NULL;
  m_2 = NULL;
}

// ---------------------------------------------------------------------------

identifier_list::~identifier_list()
{
  if (m_1 != NULL)
    delete m_1;
  if (m_2 != NULL)
    delete m_2;
}

// ---------------------------------------------------------------------------

void identifier_list::Initialize(const unsigned int in_allowed_length, const Rule *in_previous_rule)
{
  m_rule_lists.clear();

#ifndef DISABLE_PRODUCTION_LENGTH_OPTIMIZATION
  if (in_allowed_length == 1)
#endif // DISABLE_PRODUCTION_LENGTH_OPTIMIZATION
  {
    if (m_1 == NULL)
      m_1 = new match_1;

    m_rule_lists.push_back(m_1);
  }

#ifndef DISABLE_PRODUCTION_LENGTH_OPTIMIZATION
  if (in_allowed_length >= 1)
#endif // DISABLE_PRODUCTION_LENGTH_OPTIMIZATION
  {
    if (m_2 == NULL)
      m_2 = new match_2;

    m_rule_lists.push_back(m_2);
  }

  Nonterminal_Rule::Initialize(in_allowed_length, in_previous_rule);
}

// ---------------------------------------------------------------------------

int main(int argc, char *argv[])
{
  list< list< string > > results;

  {
    identifier_list start;

    start.Initialize(2);

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
    expected_results.push_back(temp_string_list);
  }

  {
    list<string> temp_string_list;
    temp_string_list.push_back("id_1");
    temp_string_list.push_back("id_2");
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
