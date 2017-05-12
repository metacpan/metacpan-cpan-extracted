#include "generator/rule/rule.h"
#include "generator/utility/utility.h"

// ---------------------------------------------------------------------------

Rule::Rule()
{
  m_is_valid = true;
  m_needs_reset = true;
  m_accessed = false;
}

// ---------------------------------------------------------------------------

Rule::~Rule()
{
}

// ---------------------------------------------------------------------------

void Rule::Initialize(const unsigned int in_allowed_length, const Rule *in_previous_rule)
{
  m_allowed_length = in_allowed_length;
  m_previous_rule = in_previous_rule;
  m_needs_reset = true;
  m_accessed = false;
}

// ---------------------------------------------------------------------------

const unsigned int Rule::Get_Allowed_Length() const
{
  return m_allowed_length;
}

// ---------------------------------------------------------------------------

const Rule* Rule::Get_Previous_Rule() const
{
  return m_previous_rule;
}

// ---------------------------------------------------------------------------

void Rule::Reset_String()
{
  m_is_valid = true;
  m_needs_reset = false;
  m_accessed = false;
}

// ---------------------------------------------------------------------------

const bool Rule::Check_For_String()
{
  if (Needs_Reset())
    this->Reset_String();

  if (!Is_Valid())
    return false;

  return true;
}

// ---------------------------------------------------------------------------

void Rule::Invalidate()
{
  m_is_valid = false;
}

// ---------------------------------------------------------------------------

const bool Rule::Is_Valid()
{
  if (Needs_Reset())
    Reset_String();

  return m_is_valid;
}

// ---------------------------------------------------------------------------

const bool Rule::Needs_Reset() const
{
  return m_needs_reset;
}

// ---------------------------------------------------------------------------

const bool Rule::Get_Accessed() const
{
  return m_accessed;
}

// ---------------------------------------------------------------------------

void Rule::Set_Accessed(const bool accessed)
{
  m_accessed = accessed;
}

// ---------------------------------------------------------------------------

ostream& operator<< (ostream& in_ostream, const vector<Rule*>& in_rule_list)
{
  {
    in_ostream << "<";

    vector<Rule*>::const_iterator a_rule;
    for (a_rule = in_rule_list.begin(); a_rule != in_rule_list.end(); a_rule++)
    {
      if (a_rule != in_rule_list.begin())
        in_ostream << ',';
      in_ostream << Utility::readable_type_name(typeid(**a_rule));
//      in_ostream << *a_rule <<
//        "(" << Utility::readable_type_name(typeid(**a_rule)) << ")";
    }

    in_ostream << ">";
  }

  return in_ostream;
}

// ---------------------------------------------------------------------------

ostream& operator<< (ostream& in_ostream,
  const vector<const Rule*>& in_rule_list)
{
  {
    in_ostream << "<";

    vector<const Rule*>::const_iterator a_rule;
    for (a_rule = in_rule_list.begin(); a_rule != in_rule_list.end(); a_rule++)
    {
      if (a_rule != in_rule_list.begin())
        in_ostream << ',';
      in_ostream << Utility::readable_type_name(typeid(**a_rule));
//      in_ostream << *a_rule <<
//        "(" << Utility::readable_type_name(typeid(**a_rule)) << ")";
    }

    in_ostream << ">";
  }

  return in_ostream;
}

// ---------------------------------------------------------------------------

ostream& operator<< (ostream& in_ostream, const list<Rule*>& in_rule_list)
{
  {
    in_ostream << "<";

    list<Rule*>::const_iterator a_rule;
    for (a_rule = in_rule_list.begin(); a_rule != in_rule_list.end(); a_rule++)
    {
      if (a_rule != in_rule_list.begin())
        in_ostream << ',';
      in_ostream << Utility::readable_type_name(typeid(**a_rule));
//      in_ostream << *a_rule <<
//        "(" << Utility::readable_type_name(typeid(**a_rule)) << ")";
    }

    in_ostream << ">";
  }

  return in_ostream;
}

// ---------------------------------------------------------------------------

ostream& operator<< (ostream& in_ostream,
  const list<const Rule*>& in_rule_list)
{
  {
    in_ostream << "<";

    list<const Rule*>::const_iterator a_rule;
    for (a_rule = in_rule_list.begin(); a_rule != in_rule_list.end(); a_rule++)
    {
      if (a_rule != in_rule_list.begin())
        in_ostream << ',';
      in_ostream << Utility::readable_type_name(typeid(**a_rule));
//      in_ostream << *a_rule <<
//        "(" << Utility::readable_type_name(typeid(**a_rule)) << ")";
    }

    in_ostream << ">";
  }

  return in_ostream;
}

