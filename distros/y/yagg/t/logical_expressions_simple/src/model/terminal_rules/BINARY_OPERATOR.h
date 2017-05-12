#ifndef BINARY_OPERATOR_h
#define BINARY_OPERATOR_h

#include "generator/rule/terminal_rule.h"
#include "model/utility/terminal_utility.h"

class BINARY_OPERATOR : public Terminal_Rule
{
public:
  virtual const bool Check_For_String();
  virtual const list<string>& Get_String() const;
  virtual const string& Get_Value();

protected:
  list<string> strings;
  string return_value;
};

#endif // BINARY_OPERATOR_h
