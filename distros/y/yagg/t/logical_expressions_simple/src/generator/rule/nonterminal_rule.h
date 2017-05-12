#ifndef NONTERMINAL_RULE_H
#define NONTERMINAL_RULE_H

#include <string>
#include <list>

using namespace std;

#include "generator/rule/rule.h"
#include "generator/rule_list/rule_list.h"

class Nonterminal_Rule : public Rule
{
public:
  virtual ~Nonterminal_Rule();

  virtual void Reset_String();

  virtual const bool Check_For_String();
  virtual const list<string>& Get_String() const;

  virtual const Rule* operator[](const unsigned int in_index) const;

protected:
  Nonterminal_Rule();

private:
  Nonterminal_Rule(const Nonterminal_Rule &in_nonterminal);

protected:
  list<Rule_List*> m_rule_lists;
  list<Rule_List*>::iterator m_current_rule_list;

  static set< pair<string,unsigned int> > m_previous_reset_rules;
};

#endif // NONTERMINAL_RULE_H
