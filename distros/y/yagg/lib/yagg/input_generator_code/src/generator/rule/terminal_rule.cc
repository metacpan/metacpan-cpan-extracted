#include "generator/rule/terminal_rule.h"
#include <cassert>

#ifdef SHORT_RULE_TRACE
#include <iostream>
#include "generator/utility/utility.h"

using namespace Utility;
#endif // SHORT_RULE_TRACE

using namespace std;

Terminal_Rule::Terminal_Rule()
{
  m_string_count = 0;

  m_terminals.push_back(this);
}

// ---------------------------------------------------------------------------

Terminal_Rule::~Terminal_Rule()
{
}

// ---------------------------------------------------------------------------

void Terminal_Rule::Initialize(const unsigned int in_allowed_length, const Rule *in_previous_rule)
{
  Rule::Initialize(in_allowed_length,in_previous_rule);
}

// ---------------------------------------------------------------------------

void Terminal_Rule::Reset_String()
{
  Rule::Reset_String();

#ifdef SHORT_RULE_TRACE
  cerr << "RESET: " << Utility::indent << 
    "Terminal: " << Utility::readable_type_name(typeid(*this)) <<
    "(" << m_allowed_length << ")" << endl;
  Utility::Indent();
#endif // SHORT_RULE_TRACE

  m_string_count = 0;

  if (m_allowed_length != 1)
  {
#ifdef SHORT_RULE_TRACE
    cerr << "RESET: " << Utility::indent <<
      "Terminal: " <<  Utility::readable_type_name(typeid(*this)) <<
      " -> NOT VALID" << endl;
    Utility::Unindent();
#endif // SHORT_RULE_TRACE

    Invalidate();

    return;
  }

#ifdef SHORT_RULE_TRACE
  cerr << "RESET: " << Utility::indent <<
      "Terminal: " <<  Utility::readable_type_name(typeid(*this)) <<
      " -> VALID" << endl;
  Utility::Unindent();
#endif // SHORT_RULE_TRACE
}

// ---------------------------------------------------------------------------

const bool Terminal_Rule::Check_For_String()
{
#ifdef SHORT_RULE_TRACE
  cerr << "CHECK: " << Utility::indent << "Terminal: " <<
    Utility::readable_type_name(typeid(*this)) << "(" << m_allowed_length << ")";

  list<const Rule*> previous_rules;

  for (const Rule* a_rule = m_previous_rule;
       a_rule != NULL;
       a_rule = a_rule->Get_Previous_Rule())
    previous_rules.push_front(a_rule);

  cerr << " (Prefix rules: " << previous_rules << ")" << endl;
  Utility::Indent();
#endif // SHORT_RULE_TRACE

  if (!Rule::Check_For_String())
  {
#ifdef SHORT_RULE_TRACE
    cerr << "CHECK: " << Utility::indent <<
      "Terminal: " <<  Utility::readable_type_name(typeid(*this)) <<
      " -> NOT VALID" << endl;
    Utility::Unindent();
#endif // SHORT_RULE_TRACE

    return false;
  }

  m_string_count++;

  // Default implementation assumes 1 string per terminal
  if (m_string_count > 1)
  {
#ifdef SHORT_RULE_TRACE
    cerr << "CHECK: " << Utility::indent <<
      "Terminal: " <<  Utility::readable_type_name(typeid(*this)) <<
      " -> NOT VALID" << endl;
    Utility::Unindent();
#endif // SHORT_RULE_TRACE

    return false;
  }
  else
  {
#ifdef SHORT_RULE_TRACE
    cerr << "CHECK: " << Utility::indent <<
      "Terminal: " <<  Utility::readable_type_name(typeid(*this)) <<
      " -> VALID" << endl;
    Utility::Unindent();
#endif // SHORT_RULE_TRACE

    return true;
  }
}

// ---------------------------------------------------------------------------

const Rule* Terminal_Rule::operator[](const unsigned int in_index) const
{
  assert (in_index == 0);

  return this;
}

