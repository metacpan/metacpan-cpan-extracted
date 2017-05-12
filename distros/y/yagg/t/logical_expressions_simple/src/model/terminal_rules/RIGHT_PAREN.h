#ifndef RIGHT_PAREN_h
#define RIGHT_PAREN_h

#include "generator/rule/terminal_rule.h"
#include "model/utility/terminal_utility.h"

class RIGHT_PAREN : public Terminal_Rule
{
public:
  RIGHT_PAREN();

  virtual const bool Check_For_String();
  virtual const list<string>& Get_String() const;
  virtual const string& Get_Value();

protected:
  list<string> strings;
  string return_value;
};

#endif // RIGHT_PAREN_h
