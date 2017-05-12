#ifndef [[[$nonterminal]]]_h
#define [[[$nonterminal]]]_h

#include "generator/rule/nonterminal_rule.h"
#include "model/utility/nonterminal_utility.h"

class [[[$nonterminal]]] : public Nonterminal_Rule
{
[[[
for (my $i = 1; $i <= @productions; $i++)
{
  $OUT .= "  class match_$i;\n";
}
]]]
public:
  [[[$nonterminal]]]();
  virtual ~[[[$nonterminal]]]();

  virtual void Initialize(const unsigned int in_allowed_length, const Rule *in_previous_rule = NULL);
[[[
if (defined $return_type)
{
  $OUT .= "\n  virtual const $return_type Get_Value();\n";
}
]]]
protected:
[[[
foreach my $i (1..$#productions+1)
{
  $OUT .= "  match_$i *m_$i;\n";
}
]]]};

#endif // [[[$nonterminal]]]_h
