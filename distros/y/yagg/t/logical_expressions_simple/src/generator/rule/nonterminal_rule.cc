#include "generator/rule/nonterminal_rule.h"
#include <cxxabi.h>
#include <set>
#include <cassert>

#ifdef SHORT_RULE_TRACE
#include <iostream>
#include "generator/utility/utility.h"

using namespace Utility;
#endif // SHORT_RULE_TRACE

using namespace std;

set< pair<string,unsigned int> > Nonterminal_Rule::m_previous_reset_rules;

// ---------------------------------------------------------------------------

Nonterminal_Rule::Nonterminal_Rule()
{
  m_current_rule_list = m_rule_lists.end();
}

// ---------------------------------------------------------------------------

Nonterminal_Rule::~Nonterminal_Rule()
{
}

// ---------------------------------------------------------------------------

void Nonterminal_Rule::Reset_String()
{
#ifdef SHORT_RULE_TRACE
  cerr << "RESET: " << Utility::indent << 
    "Nonterminal: " << Utility::readable_type_name(typeid(*this)) <<
    "(" << m_allowed_length << ")" << endl;
  Utility::Indent();
#endif // SHORT_RULE_TRACE

  // First avoid recursion
  pair<string, unsigned int> rule_info;
  rule_info.first = (typeid(*this)).name();
  rule_info.second = m_allowed_length;

  if (m_previous_reset_rules.find(rule_info) != m_previous_reset_rules.end())
  {
#ifdef SHORT_RULE_TRACE
    cerr << "RESET: " << Utility::indent <<
      "Nonterminal: " << Utility::readable_type_name(typeid(*this)) <<
      " -> NOT VALID (RECURSION)" << endl;
    Utility::Unindent();
#endif // SHORT_RULE_TRACE

    Invalidate();
    return;
  }

  m_previous_reset_rules.insert(rule_info);


  Rule::Reset_String();

  if (m_rule_lists.empty())
  {
#ifdef SHORT_RULE_TRACE
    cerr << "RESET: " << Utility::indent <<
      "Nonterminal: " << Utility::readable_type_name(typeid(*this)) <<
      " -> NOT VALID (EMPTY)" << endl;
    Utility::Unindent();
#endif // SHORT_RULE_TRACE

    Invalidate();

    // Clear the recursion prevention data
    m_previous_reset_rules.erase(rule_info);

    return;
  }

  m_current_rule_list = m_rule_lists.begin();

  while(m_current_rule_list != m_rule_lists.end())
  {
#ifdef SHORT_RULE_TRACE
    cerr << "RESET: " << Utility::indent << "Rule list " <<
      (vector<Rule*>)(**m_current_rule_list) << "(" << m_allowed_length <<
      ")" << endl;
    Utility::Indent();
#endif // SHORT_RULE_TRACE

    (*m_current_rule_list)->Initialize(m_allowed_length,m_previous_rule);

    if((*m_current_rule_list)->Is_Valid())
      break;

#ifdef SHORT_RULE_TRACE
    cerr << "RESET: " << Utility::indent <<
      "Nonterminal: " <<  Utility::readable_type_name(typeid(*this)) <<
      " -> NOT VALID (RULE LIST INVALID)" << endl;
    Utility::Unindent();
#endif // SHORT_RULE_TRACE

    m_current_rule_list++;
  }

  if (m_current_rule_list != m_rule_lists.end())
  {
#ifdef SHORT_RULE_TRACE
    cerr << "RESET: " << Utility::indent << "Rule list " <<
      (vector<Rule*>)(**m_current_rule_list) << "(" << m_allowed_length <<
    ")" <<
      " -> VALID" << endl;
    Utility::Unindent();

    cerr << "RESET: " << Utility::indent <<
      "Nonterminal: " <<  Utility::readable_type_name(typeid(*this)) <<
      " -> VALID" << endl;
    Utility::Unindent();
#endif // SHORT_RULE_TRACE
  }
  else
  {
#ifdef SHORT_RULE_TRACE
    cerr << "RESET: " << Utility::indent <<
      "Nonterminal: " <<  Utility::readable_type_name(typeid(*this)) <<
      " -> NOT VALID (ALL RULE LISTS INVALID)" << endl;
    Utility::Unindent();
#endif // SHORT_RULE_TRACE

    Invalidate();
  }

  // Clear the recursion prevention data
  m_previous_reset_rules.erase(rule_info);
}

// ---------------------------------------------------------------------------

const bool Nonterminal_Rule::Check_For_String()
{
#ifdef SHORT_RULE_TRACE
  cerr << "CHECK: " << Utility::indent << "Nonterminal: " <<
    Utility::readable_type_name(typeid(*this)) << "(" << m_allowed_length << ")";

  list<const Rule*> previous_rules;

  for (const Rule* a_rule = m_previous_rule;
       a_rule != NULL;
       a_rule = a_rule->Get_Previous_Rule())
    previous_rules.push_front(a_rule);

  cerr << " (Prefix rules: " << previous_rules << ")" << endl;

  Utility::Indent();
#endif // SHORT_RULE_TRACE

  if (!Rule::Check_For_String() || m_current_rule_list == m_rule_lists.end())
  {
#ifdef SHORT_RULE_TRACE
    cerr << "CHECK: " << Utility::indent <<
      "Nonterminal: " <<  Utility::readable_type_name(typeid(*this)) <<
      " -> NOT VALID" << endl;
    Utility::Unindent();
#endif // SHORT_RULE_TRACE

    return false;
  }

#ifdef SHORT_RULE_TRACE
  cerr << "CHECK: " << Utility::indent << "Rule list " <<
    (vector<Rule*>)(**m_current_rule_list) << "(" << m_allowed_length <<
    ") TRYING" << endl;
  Utility::Indent();
#endif // SHORT_RULE_TRACE

  while(1)
  {
    if ((*m_current_rule_list)->Check_For_String())
      break;

#ifdef SHORT_RULE_TRACE
    cerr << "CHECK: " << Utility::indent <<
      "Rule list: " << **m_current_rule_list << " -> NOT VALID" << endl;
    Utility::Unindent();
#endif // SHORT_RULE_TRACE

    m_current_rule_list++;

    if(m_current_rule_list == m_rule_lists.end())
      break;

#ifdef SHORT_RULE_TRACE
    cerr << "CHECK: " << Utility::indent << "Rule list " <<
      (vector<Rule*>)(**m_current_rule_list) << "(" << m_allowed_length <<
      ") TRYING" << endl;
    Utility::Indent();
#endif // SHORT_RULE_TRACE

    (*m_current_rule_list)->Initialize(m_allowed_length,m_previous_rule);
  }

  if(m_current_rule_list == m_rule_lists.end())
  {
#ifdef SHORT_RULE_TRACE
    cerr << "CHECK: " << Utility::indent <<
      "Nonterminal: " <<  Utility::readable_type_name(typeid(*this)) <<
      " -> NOT VALID" << endl;
    Utility::Unindent();
#endif // SHORT_RULE_TRACE

    return false;
  }
  else
  {
#ifdef SHORT_RULE_TRACE
    cerr << "CHECK: " << Utility::indent <<
      "Rule list: " <<  **m_current_rule_list << " -> VALID" << endl;
    Utility::Unindent();

    cerr << "CHECK: " << Utility::indent <<
      "Nonterminal: " << Utility::readable_type_name(typeid(*this)) <<
      " -> VALID" << endl;
    Utility::Unindent();
#endif // SHORT_RULE_TRACE

    return true;
  }
}

// ---------------------------------------------------------------------------

const list<string>& Nonterminal_Rule::Get_String() const
{
  assert(m_current_rule_list != m_rule_lists.end());

  return (*m_current_rule_list)->Get_String();
}

// ---------------------------------------------------------------------------

const Rule* Nonterminal_Rule::operator[](const unsigned int in_index) const
{
  assert(in_index <= (*m_current_rule_list)->size()-1);

  return ((**m_current_rule_list)[in_index]);
}

// ---------------------------------------------------------------------------
