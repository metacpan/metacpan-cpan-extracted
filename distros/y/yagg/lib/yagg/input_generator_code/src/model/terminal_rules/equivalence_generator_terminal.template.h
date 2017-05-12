#ifndef [[[$terminal]]]_h
#define [[[$terminal]]]_h

#include "generator/rule/terminal_rule.h"
#include "model/utility/terminal_utility.h"

class [[[$terminal]]] : public Terminal_Rule
{
public:
  virtual const bool Check_For_String();
  virtual const list<string>& Get_String() const;
[[[
if (defined $nonpointer_return_type)
{
  $OUT .= "  virtual const $return_type Get_Value();";
}
else
{
  $OUT .= "  virtual const $return_type& Get_Value();";
}
]]]

protected:
  list<string> strings;
[[[
if (defined $nonpointer_return_type)
{
  $OUT .= "  $nonpointer_return_type return_value;";
}
else
{
  $OUT .= "  $return_type return_value;";
}
]]]
};

#endif // [[[$terminal]]]_h
