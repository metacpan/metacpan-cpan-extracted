#include <iostream>
#include <typeinfo>
#include <cassert>

#ifdef SHORT_RULE_TRACE
#include "generator/utility/utility.h"
#endif // SHORT_RULE_TRACE

#ifndef DISABLE_ALLOCATION_CACHING_OPTIMIZATION
#include "generator/allocations/allocations_cache.h"
#endif // DISABLE_ALLOCATION_CACHING_OPTIMIZATION

using namespace std;

#include "generator/rule_list/rule_list.h"
#include "generator/rule/rule.h"

// ---------------------------------------------------------------------------

Rule_List* Rule_List::CURRENTLY_ACTIVE_RULE_LIST;

#ifndef DISABLE_ALLOCATION_CACHING_OPTIMIZATION
Allocations_Cache Rule_List::m_allocations_cache;
#endif // DISABLE_ALLOCATION_CACHING_OPTIMIZATION

// ---------------------------------------------------------------------------

Rule_List::Rule_List()
{
}

// ---------------------------------------------------------------------------

Rule_List::~Rule_List()
{
  const_iterator a_rule;
  for(a_rule = begin(); a_rule != end(); a_rule++)
  {
    delete *a_rule;
  }
}

// ---------------------------------------------------------------------------

// Resets the rule list for a new maximum length.

void Rule_List::Initialize(const unsigned int in_allowed_length, const Rule *in_previous_rule)
{
  m_allowed_length = in_allowed_length;
  m_previous_rule = in_previous_rule;
  m_first_string = true;
  m_needs_reset = true;
}

// ---------------------------------------------------------------------------

// Resets the rule list, trying to find the first valid allocation.

void Rule_List::Reset_String()
{
  m_needs_reset = false;
  m_is_valid = true;

  if (size() == 0 && m_allowed_length != 0)
  {
#ifdef SHORT_RULE_TRACE
    cerr << "RESET: " << Utility::indent << "Rules: " << *this << endl;
    Utility::Indent();

    cerr << "RESET: " << Utility::indent << "Rules: " <<  *this <<
      " -> ALLOCATIONS NOT VALID" << endl;
    Utility::Unindent();
#endif // SHORT_RULE_TRACE

    Invalidate();
    return;
  }

  // First initialize to first allocation
  {
#ifndef DISABLE_ALLOCATION_CACHING_OPTIMIZATION
    m_current_allocations =
      m_allocations_cache.Get_Allocations_Iterator(*this);

    if (m_current_allocations == m_allocations_cache.End(*this) &&
        m_allocations_cache.Is_Finalized(*this))
    {
      Invalidate();
      return;
    }

    if (m_current_allocations != m_allocations_cache.End(*this))
      Set_Allocations(*m_current_allocations);
    else
#endif // DISABLE_ALLOCATION_CACHING_OPTIMIZATION
    {
      vector < unsigned int > initial_allocations(size(),0);
      if (size() > 0)
        initial_allocations[0] = m_allowed_length;

      Set_Allocations(initial_allocations);
    }
  }

  // Now check that there is a valid allocation
  if (Allocation_Is_Valid())
  {
#ifndef DISABLE_ALLOCATION_CACHING_OPTIMIZATION
    m_allocations_cache.Store_Allocations(*this);
#endif // DISABLE_ALLOCATION_CACHING_OPTIMIZATION

    return;
  }

  if (!Find_Next_Valid_Allocation())
    Invalidate();
}

// ---------------------------------------------------------------------------

void Rule_List::Invalidate()
{
  m_is_valid = false;
}

// ---------------------------------------------------------------------------

const bool Rule_List::Is_Valid()
{
  if (m_needs_reset)
    Reset_String();

  return m_is_valid;
}

// ---------------------------------------------------------------------------

const bool Rule_List::Check_For_String()
{
  if (m_needs_reset)
    Reset_String();

#ifdef SHORT_RULE_TRACE
  cerr << "CHECK: " << Utility::indent << *this <<
    "(" << m_allowed_length << ")";

  list<const Rule*> previous_rules;

  for (const Rule* a_rule = m_previous_rule;
       a_rule != NULL;
       a_rule = a_rule->Get_Previous_Rule())
    previous_rules.push_front(a_rule);

  cerr << " (Prefix rules: " << previous_rules << ")" << endl;
  Utility::Indent();
#endif // SHORT_RULE_TRACE

  if (!Is_Valid())
  {
#ifdef SHORT_RULE_TRACE
    cerr << "CHECK: " << Utility::indent << "Rules: " << *this << 
      " -> NOT VALID" << endl;
    Utility::Unindent();
#endif // SHORT_RULE_TRACE

    return false;
  }

  if (!m_first_string)
  {
#ifdef ACTION_TRACE
    cerr << "ACT'N: " << Utility::indent << "Calling " <<
      Utility::readable_type_name(typeid(*this)) << "::Undo_Action\n";
#endif // ACTION_TRACE
    Undo_Action();
  }

  bool string_exists = false;

  if (size() == 0)
  {
    if (m_first_string)
    {
      m_first_string = false;
      string_exists = true;
    }
  }
  else
  {
    if ((m_first_string && Check_For_String_Without_Incrementing(begin())) ||
        (!m_first_string && Check_For_String_In_Current_Allocation()) ||
        Check_For_String_In_Incremented_Allocation())
    {
      m_first_string = false;
      string_exists = true;
    }
  }

  if (string_exists)
  {
#ifdef SHORT_RULE_TRACE
    cerr << "CHECK: " << Utility::indent << "Rules: " <<  *this << 
      " -> VALID" << endl;
    Utility::Unindent();
#endif // SHORT_RULE_TRACE

    return true;
  }
  else
  {
#ifdef SHORT_RULE_TRACE
    cerr << "CHECK: " << Utility::indent << "Rules: " <<  *this << 
      " -> NOT VALID" << endl;
    Utility::Unindent();
#endif // SHORT_RULE_TRACE

    return false;
  }
}

// ---------------------------------------------------------------------------

// Checks to see if there is a string, without incrementing the string. (Note
// that this is different from Check_For_String_In_Current_Allocation in
// that Check_For_String_In_Current_Allocation increments the string.)

const bool Rule_List::Check_For_String_Without_Incrementing(const iterator in_start_rule)
{
#ifdef SHORT_RULE_TRACE
  cerr << "CHECK: " << Utility::indent << "Rules: " << *this <<
    " Check without incrementing" << endl;
  Utility::Indent();
#endif // SHORT_RULE_TRACE

  iterator a_rule = in_start_rule;

//  bool failed = false;

  while (1)
  {
//if (failed)
//cerr << "Checking for string: " <<
//Utility::readable_type_name(typeid(**a_rule)) << endl;

    if ((*a_rule)->Check_For_String())
    {
      a_rule++;

      if (a_rule != end())
      {
        // TODO: Can we avoid extra calls to Reset_String by resetting before
        // entering the loop?
//if (failed)
//cerr << "Resetting rule: " <<
//Utility::readable_type_name(typeid(**a_rule)) << endl;
        (*a_rule)->Reset_String();

        continue;
      }

      if (Check_Action())
      {
#ifdef SHORT_RULE_TRACE
        cerr << "CHECK: " << Utility::indent << "Rules: " << *this << 
          " -> Valid string exists" << endl;

        Utility::Unindent();
#endif // SHORT_RULE_TRACE

        return true;
      }

/*
{
cerr << "Failed semantic check:";
if (failed)
cerr << " (again)";
cerr << "\n<";

Rule_List::const_iterator a_rule;
for (a_rule = begin(); a_rule != end(); a_rule++)
{
if (a_rule != begin())
cerr << ',';
cerr << Utility::readable_type_name(typeid(**a_rule)) << "(" <<
(*a_rule)->Get_Accessed() << ")";
}

cerr << ">\n";
failed = true;
}
*/
    }

    if (a_rule == begin())
    {
#ifdef SHORT_RULE_TRACE
      cerr << "CHECK: " << Utility::indent << "Rules: " << *this << 
        " -> No valid string in rules" << endl;
      Utility::Unindent();
#endif // SHORT_RULE_TRACE

      return false;
    }

    a_rule--;

#ifndef DISABLE_SKIP_TO_TOUCHED_VARIABLE_OPTIMIZATION
    iterator original_rule = a_rule;

    while (a_rule != begin() && !(*a_rule)->Get_Accessed())
      a_rule--;

    // In case the action failed due to checking some external state,
    // rather than touching the rules in our rule list
    if (!(*a_rule)->Get_Accessed()) {
      a_rule = original_rule;
    } else {
      (*a_rule)->Set_Accessed(false);
    }
//a_rule = original_rule;
#endif // DISABLE_SKIP_TO_TOUCHED_VARIABLE_OPTIMIZATION
  }

  assert(false);
  return false;
}

// ---------------------------------------------------------------------------

const bool Rule_List::Check_Action()
{
  // All rules appear to have a string. Now see if the action executes
  // successfully.
  m_error_occurred = false;
  CURRENTLY_ACTIVE_RULE_LIST = this;

#ifdef ACTION_TRACE
  cerr << "ACT'N: " << Utility::indent << "Calling " <<
    Utility::readable_type_name(typeid(*this)) << "::Do_Action\n";
#endif // ACTION_TRACE
  Do_Action();

  if (!m_error_occurred)
    return true;

#ifdef ACTION_TRACE
  cerr << "ACT'N: " << Utility::indent <<  "Calling " <<
    Utility::readable_type_name(typeid(*this)) << "::Undo_Action\n";
#endif // ACTION_TRACE
  Undo_Action();

  return false;
}

// ---------------------------------------------------------------------------

const bool Rule_List::Check_For_String_In_Current_Allocation()
{
#ifdef SHORT_RULE_TRACE
  cerr << "CHECK: " << Utility::indent << "Rules: " << *this << 
    " Check in current allocations" << endl;
  Utility::Indent();
#endif // SHORT_RULE_TRACE

  // Starting from the end, see if we can increment any rules
  iterator end_rule = end();
  do
  {
    end_rule--;

    // If we find a rule we can increment, reset the following rules and
    // check that they have strings
    if (Check_For_String_Without_Incrementing(end_rule))
    {
#ifdef SHORT_RULE_TRACE
      cerr << "CHECK: " << Utility::indent << "Rules: " << *this << 
        " -> Valid string exists in current allocations" << endl;
      Utility::Unindent();
#endif // SHORT_RULE_TRACE

      return true;
    }
  }
  while (end_rule != begin());

#ifdef SHORT_RULE_TRACE
  cerr << "CHECK: " << Utility::indent << "Rules: " << *this << 
    " -> No valid string in current allocations" << endl;
  Utility::Unindent();
#endif // SHORT_RULE_TRACE

  return false;
}

// ---------------------------------------------------------------------------

const bool Rule_List::Check_For_String_In_Incremented_Allocation()
{
#ifdef SHORT_RULE_TRACE
  cerr << "CHECK: " << Utility::indent << "Rules: " << *this <<
    " Check in incremented allocations" << endl;
  Utility::Indent();
#endif // SHORT_RULE_TRACE

  while(Find_Next_Valid_Allocation())
  {
    if (Check_For_String_Without_Incrementing(begin()))
    {
#ifdef SHORT_RULE_TRACE
      cerr << "RESET: " << Utility::indent << "Rules: " <<  *this << 
        " -> String exists in incremented allocations" << endl;
      Utility::Unindent();
#endif // SHORT_RULE_TRACE

      return true;
    }
  }

#ifdef SHORT_RULE_TRACE
  cerr << "RESET: " << Utility::indent << "Rules: " <<  *this << 
    " -> No string exists in incremented allocations" << endl;
  Utility::Unindent();
#endif // SHORT_RULE_TRACE

  return false;
}

// ---------------------------------------------------------------------------

// The left-most invalid rule must be incremented.

const bool Rule_List::Find_Next_Valid_Allocation()
{
  while(1)
  {
    iterator first_invalid_rule;

    for (first_invalid_rule = begin();
         first_invalid_rule != end();
         first_invalid_rule++)
    {
      if (!(*first_invalid_rule)->Needs_Reset())
        (*first_invalid_rule)->Reset_String();

      if (!(*first_invalid_rule)->Is_Valid())
        break;
    }

    if (first_invalid_rule == end())
      first_invalid_rule--;

    unsigned int old_allocation = (*first_invalid_rule)->Get_Allowed_Length();

    while ((*first_invalid_rule)->Get_Allowed_Length() == old_allocation)
    {
      if (!Increment_Allocation())
      {
#ifndef DISABLE_ALLOCATION_CACHING_OPTIMIZATION
        m_allocations_cache.Finalize(*this);
#endif // DISABLE_ALLOCATION_CACHING_OPTIMIZATION

        return false;
      }
    }
    
    if (Allocation_Is_Valid())
    {
#ifndef DISABLE_ALLOCATION_CACHING_OPTIMIZATION
      m_allocations_cache.Store_Allocations(*this);
#endif // DISABLE_ALLOCATION_CACHING_OPTIMIZATION

      return true;
    }
  }
}

// ---------------------------------------------------------------------------

const bool Rule_List::Allocation_Is_Valid()
{
#ifdef SHORT_RULE_TRACE
  cerr << "RESET: " << Utility::indent << "Rules: " << *this <<
    " TRYING ALLOCATIONS" << endl;
  Utility::Indent();
#endif // SHORT_RULE_TRACE

  for (iterator a_rule = begin(); a_rule != end(); a_rule++)
  {
    if (!(*a_rule)->Is_Valid())
    {
#ifdef SHORT_RULE_TRACE
      cerr << "RESET: " << Utility::indent << "Rules: " <<  *this << 
        " -> ALLOCATIONS NOT VALID" << endl;
      Utility::Unindent();
#endif // SHORT_RULE_TRACE

      return false;
    }
  }

#ifdef SHORT_RULE_TRACE
  cerr << "RESET: " << Utility::indent << "Rules: " <<  *this <<
    " -> ALLOCATIONS VALID" << endl;
  Utility::Unindent();
#endif // SHORT_RULE_TRACE

  return true;
}

// ---------------------------------------------------------------------------

void Rule_List::Do_Action()
{
}

// ---------------------------------------------------------------------------

void Rule_List::Undo_Action()
{
}

// ---------------------------------------------------------------------------

const list<string>& Rule_List::Get_String()
{
  strings.clear();

  if (size() == 0)
    return strings;

  assert(Is_Valid());

  const_iterator a_rule;
  for(a_rule = begin(); a_rule != end(); a_rule++)
  {
    list<string> temp_strings = (*a_rule)->Get_String();
    strings.insert( strings.end(), temp_strings.begin(), temp_strings.end() );
  }

  return strings;
}

// ---------------------------------------------------------------------------

const bool Rule_List::Increment_Allocation()
{
  iterator end_rule = end();
  end_rule--;

  unsigned int last_allocation = (*end_rule)->Get_Allowed_Length();

  if (last_allocation == m_allowed_length)
  {
    return false;
  }

  (*end_rule)->Initialize( 0, (*end_rule)->Get_Previous_Rule() );

  iterator a_rule = end_rule;

  do
  {
    assert(a_rule != begin());
    a_rule--;
  } while ((*a_rule)->Get_Allowed_Length() == 0);

  (*a_rule)->Initialize( (*a_rule)->Get_Allowed_Length() - 1,
    (*a_rule)->Get_Previous_Rule() );

  a_rule++;

  (*a_rule)->Initialize( last_allocation + 1,
    (*a_rule)->Get_Previous_Rule() );

  return true;
}

// ---------------------------------------------------------------------------

#ifndef DISABLE_ALLOCATION_CACHING_OPTIMIZATION
const unsigned int Rule_List::Get_Allowed_Length() const
{
  return m_allowed_length;
}

// ---------------------------------------------------------------------------

const vector< unsigned int > Rule_List::Get_Allocations() const
{
  vector< unsigned int > allocations;

  const_iterator a_rule;
  for (a_rule = begin(); a_rule != end(); a_rule++)
    allocations.push_back((*a_rule)->Get_Allowed_Length());

  return allocations;
}
#endif // DISABLE_ALLOCATION_CACHING_OPTIMIZATION

// ---------------------------------------------------------------------------

void Rule_List::Set_Allocations(const vector< unsigned int > &in_allocations)
{
  const_iterator a_rule;
  const Rule *previous_rule;
  vector< unsigned int >::const_iterator an_allocation;
  for (a_rule = begin(), previous_rule = m_previous_rule, an_allocation =
         in_allocations.begin();
       a_rule != end();
       previous_rule = *a_rule, a_rule++, an_allocation++)
  {
    (*a_rule)->Initialize(*an_allocation, previous_rule);
  }
}

// ---------------------------------------------------------------------------

#ifdef SHORT_RULE_TRACE
ostream& operator<< (ostream& in_ostream, const Rule_List& in_rule_list)
{
  in_ostream << "<";

  Rule_List::const_iterator a_rule;
  for (a_rule = in_rule_list.begin(); a_rule != in_rule_list.end(); a_rule++)
  {
    if (a_rule != in_rule_list.begin())
      in_ostream << ',';
    in_ostream << Utility::readable_type_name(typeid(**a_rule)) << "(" <<
      (*a_rule)->Get_Allowed_Length() << ")";
  }

  in_ostream << ">";

  return in_ostream;
}
#endif // SHORT_RULE_TRACE

// ---------------------------------------------------------------------------
