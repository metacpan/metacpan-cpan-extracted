#ifndef RULE_H
#define RULE_H

#include <string>
#include <list>
#include <vector>
#include <iostream>
#include <typeinfo>

using namespace std;

class Rule
{
  friend class Rule_List;

public:
  virtual ~Rule();

  virtual void Initialize(const unsigned int in_allowed_length, const Rule* in_previous_rule = NULL);
  virtual const unsigned int Get_Allowed_Length() const;
  virtual void Reset_String();

  virtual void Invalidate();
  virtual const bool Is_Valid();
  virtual const bool Needs_Reset() const;

  virtual const bool Check_For_String();
  virtual const list<string>& Get_String() const = 0;

  virtual const Rule* Get_Previous_Rule() const;

  virtual const Rule* operator[](const unsigned int in_index) const = 0;

  virtual const bool Get_Accessed() const;
  virtual void Set_Accessed(const bool accessed);

protected:
  Rule();

private:
  Rule(const Rule &in_rule);

protected:
  const Rule* m_previous_rule;
  unsigned int m_allowed_length;
  bool m_is_valid;
  bool m_needs_reset;
  bool m_accessed;
};

ostream& operator<< (ostream& in_ostream,
    const vector<Rule*>& in_rule_list);
ostream& operator<< (ostream& in_ostream,
    const vector<const Rule*>& in_rule_list);
ostream& operator<< (ostream& in_ostream,
    const list<Rule*>& in_rule_list);
ostream& operator<< (ostream& in_ostream,
    const list<const Rule*>& in_rule_list);

#endif // RULE_H
