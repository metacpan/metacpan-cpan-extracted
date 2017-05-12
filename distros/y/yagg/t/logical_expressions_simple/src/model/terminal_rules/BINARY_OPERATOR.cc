#include "model/terminal_rules/BINARY_OPERATOR.h"

#include <cassert>
#include <list>

using namespace std;

// ---------------------------------------------------------------------------

const bool BINARY_OPERATOR::Check_For_String()
{
  if (!Is_Valid())
    return false;

  m_string_count++;

  if (m_string_count > 4)
    return false;

  switch (m_string_count)
  {
    case 1 :
    {
      return_value = "<=>";
      break;
    }
    case 2 :
    {
      return_value = "and";
      break;
    }
    case 3 :
    {
      return_value = "or";
      break;
    }
    case 4 :
    {
      return_value = "=>";
      break;
    }

  }

  strings.clear();

  strings.push_back(return_value);

  return true;
}

// ---------------------------------------------------------------------------

const list<string>& BINARY_OPERATOR::Get_String() const
{
  assert(m_string_count <= 4);

  return strings;
}

// ---------------------------------------------------------------------------

const string& BINARY_OPERATOR::Get_Value()
{
  Set_Accessed(true);

  return return_value;
}
