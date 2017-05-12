#include "model/terminal_rules/RIGHT_PAREN.h"

#include <list>

using namespace std;

// ---------------------------------------------------------------------------

RIGHT_PAREN::RIGHT_PAREN()
{
  return_value = ")";

  strings.clear();

  strings.push_back(return_value);
}

// ---------------------------------------------------------------------------

const bool RIGHT_PAREN::Check_For_String()
{
  m_string_count++;

  if (m_string_count > 1)
    return false;

  if (!Is_Valid())
    return false;

  return true;
}

// ---------------------------------------------------------------------------

const list<string>& RIGHT_PAREN::Get_String() const
{
  return strings;
}

// ---------------------------------------------------------------------------

const string& RIGHT_PAREN::Get_Value()
{
  Set_Accessed(true);

  return return_value;
}
