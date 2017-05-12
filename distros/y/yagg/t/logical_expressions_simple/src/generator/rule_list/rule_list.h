#ifndef RULE_LIST_H
#define RULE_LIST_H

#include <list>
#include <string>
#include <vector>
#include <iostream>
#include <utility>
#include <set>

#ifndef DISABLE_ALLOCATION_CACHING_OPTIMIZATION
#include "generator/allocations/allocations_cache.h"
#endif // DISABLE_ALLOCATION_CACHING_OPTIMIZATION

using namespace std;

#include "generator/utility/utility.h"

class Rule;

class Rule_List : public vector<Rule*>
{
  friend class Nonterminal_Rule;

#ifdef SHORT_RULE_TRACE
  friend string Utility::to_string(
      const Rule_List &in_rule_list, const bool &in_show_lengths);
#endif // SHORT_RULE_TRACE

public:
  Rule_List();

  virtual ~Rule_List();

  virtual void Initialize(const unsigned int in_allowed_length, const Rule *in_previous_rule = NULL);
  virtual void Reset_String();

  virtual void Invalidate();
  virtual const bool Is_Valid();

  virtual const bool Check_For_String();
  virtual const list<string>& Get_String();

#ifndef DISABLE_ALLOCATION_CACHING_OPTIMIZATION
  virtual const unsigned int Get_Allowed_Length() const;
  virtual const vector< unsigned int > Get_Allocations() const;
#endif // DISABLE_ALLOCATION_CACHING_OPTIMIZATION

  virtual void Set_Allocations(const vector< unsigned int > &in_allocations);

  friend ostream& operator<< (ostream& in_ostream, const Rule_List& in_rule_list);
  friend void Utility::yyerror();

private:
  Rule_List(const Rule_List &in_rule_list);

protected:
  virtual const bool Check_For_String_Without_Incrementing(
      const iterator in_start_rule);
  virtual const bool Check_Action();
  virtual const bool Check_For_String_In_Current_Allocation();
  virtual const bool Check_For_String_In_Incremented_Allocation();

  virtual const bool Find_Next_Valid_Allocation();
  virtual const bool Increment_Allocation();
  virtual const bool Allocation_Is_Valid();

  virtual void Do_Action();
  virtual void Undo_Action();

  const Rule *m_previous_rule;
  unsigned int m_allowed_length;
  bool m_is_valid;
  bool m_needs_reset;
  bool m_first_string;
  bool m_error_occurred;

  list<const Rule*> m_terminals;

  list<string> strings;

#ifndef DISABLE_ALLOCATION_CACHING_OPTIMIZATION
  static Allocations_Cache m_allocations_cache;
  list< vector< unsigned int > >::const_iterator m_current_allocations;
#endif // DISABLE_ALLOCATION_CACHING_OPTIMIZATION

  static Rule_List* CURRENTLY_ACTIVE_RULE_LIST;
};

#endif // RULE_LIST_H
