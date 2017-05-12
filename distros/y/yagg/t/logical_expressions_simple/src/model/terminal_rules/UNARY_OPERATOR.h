#ifndef UNARY_OPERATOR_h
#define UNARY_OPERATOR_h

#include "generator/rule/terminal_rule.h"
#include "model/utility/terminal_utility.h"

class UNARY_OPERATOR : public Terminal_Rule
{
public:
  UNARY_OPERATOR();

  virtual const bool Check_For_String();
  virtual const list<string>& Get_String() const;
  virtual const string& Get_Value();

protected:
  list<string> strings;
  string return_value;
};

#endif // UNARY_OPERATOR_h
