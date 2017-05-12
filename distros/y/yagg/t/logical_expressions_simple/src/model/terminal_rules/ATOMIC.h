#ifndef ATOMIC_h
#define ATOMIC_h

#include "generator/rule/terminal_rule.h"
#include "model/utility/terminal_utility.h"

class ATOMIC : public Terminal_Rule
{
public:
  virtual const bool Check_For_String();
  virtual const list<string>& Get_String() const;
  virtual const string& Get_Value();

protected:
  list<string> strings;
  string return_value;
};

#endif // ATOMIC_h
