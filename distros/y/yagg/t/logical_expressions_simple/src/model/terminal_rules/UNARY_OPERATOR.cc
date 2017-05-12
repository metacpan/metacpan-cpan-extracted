#include "model/terminal_rules/UNARY_OPERATOR.h"

#include <list>

using namespace std;

// ---------------------------------------------------------------------------

UNARY_OPERATOR::UNARY_OPERATOR()
{
  return_value = "-";

  strings.clear();

  strings.push_back(return_value);
}

// ---------------------------------------------------------------------------

const bool UNARY_OPERATOR::Check_For_String()
{
  m_string_count++;

  if (m_string_count > 1)
    return false;

  if (!Is_Valid())
    return false;

  return true;
}

// ---------------------------------------------------------------------------

const list<string>& UNARY_OPERATOR::Get_String() const
{
  return strings;
}

// ---------------------------------------------------------------------------

const string& UNARY_OPERATOR::Get_Value()
{
  Set_Accessed(true);

  return return_value;
}
