#include "model/terminal_rules/LEFT_PAREN.h"

#include <list>

using namespace std;

// ---------------------------------------------------------------------------

LEFT_PAREN::LEFT_PAREN()
{
  return_value = "(";

  strings.clear();

  strings.push_back(return_value);
}

// ---------------------------------------------------------------------------

const bool LEFT_PAREN::Check_For_String()
{
  m_string_count++;

  if (m_string_count > 1)
    return false;

  if (!Is_Valid())
    return false;

  return true;
}

// ---------------------------------------------------------------------------

const list<string>& LEFT_PAREN::Get_String() const
{
  return strings;
}

// ---------------------------------------------------------------------------

const string& LEFT_PAREN::Get_Value()
{
  Set_Accessed(true);

  return return_value;
}
