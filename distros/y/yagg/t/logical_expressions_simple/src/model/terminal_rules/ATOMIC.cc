#include "model/terminal_rules/ATOMIC.h"

#include <cassert>
#include <list>

using namespace std;

// ---------------------------------------------------------------------------

const bool ATOMIC::Check_For_String()
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
      return_value = "p";
      break;
    }
    case 2 :
    {
      return_value = "q";
      break;
    }
    case 3 :
    {
      return_value = "r";
      break;
    }

  }

  strings.clear();

  strings.push_back(return_value);

  return true;
}

// ---------------------------------------------------------------------------

const list<string>& ATOMIC::Get_String() const
{
  assert(m_string_count <= 3);

  return strings;
}

// ---------------------------------------------------------------------------

const string& ATOMIC::Get_Value()
{
  Set_Accessed(true);

  return return_value;
}
