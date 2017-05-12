#ifndef TERMINAL_RULE_H
#define TERMINAL_RULE_H

#include <string>
#include <list>

using namespace std;

#include "generator/rule/rule.h"

class Terminal_Rule : public Rule
{
public:
  virtual ~Terminal_Rule();

  virtual void Initialize(const unsigned int in_allowed_length, const Rule *in_previous_rule = NULL);
  virtual void Reset_String();

  virtual const bool Check_For_String();
  virtual const list<string>& Get_String() const = 0;

  virtual const Rule* operator[](const unsigned int in_index) const;

protected:
  Terminal_Rule();

private:
  Terminal_Rule(const Terminal_Rule &in_terminal);

protected:
  unsigned int m_string_count;

  list<const Rule*> m_terminals;
};

#endif // TERMINAL_RULE_H
