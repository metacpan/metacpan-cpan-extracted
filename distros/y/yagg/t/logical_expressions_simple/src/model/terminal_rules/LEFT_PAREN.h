#ifndef LEFT_PAREN_h
#define LEFT_PAREN_h

#include "generator/rule/terminal_rule.h"
#include "model/utility/terminal_utility.h"

class LEFT_PAREN : public Terminal_Rule
{
public:
  LEFT_PAREN();

  virtual const bool Check_For_String();
  virtual const list<string>& Get_String() const;
  virtual const string& Get_Value();

protected:
  list<string> strings;
  string return_value;
};

#endif // LEFT_PAREN_h
