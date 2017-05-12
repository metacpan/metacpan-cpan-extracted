#include "model/nonterminal_rules/[[[$nonterminal]]].h"
#include <cassert>

#ifdef SHORT_RULE_TRACE
#include "generator/utility/utility.h"
#endif // SHORT_RULE_TRACE

[[[

  my %rules;
  foreach my $production (@productions)
  {
    foreach my $rule (@{$production->{'rules'}})
    {
      $rules{$rule} = 1;
    }
  }

  # Sort so that output files can more easily be compared
  foreach my $rule (sort keys %rules)
  {
    next if $rule eq $nonterminal;

    if (grep { $_ eq $rule } @{$grammar->{'TERMINALS'}})
    {
      $OUT .= qq{#include "model/terminal_rules/$rule.h"\n};
    }
    else
    {
      $OUT .= qq{#include "model/nonterminal_rules/$rule.h"\n};
    }
  }
]]]
#include <list>

using namespace std;

// ---------------------------------------------------------------------------

#ifndef DISABLE_GENERATED_STRING_CACHING_OPTIMIZATION
map<const unsigned int, list< list< string> > > [[[$nonterminal]]]::m_generated_cache;
map<const unsigned int, list< list< string> > > [[[$nonterminal]]]::m_intermediate_cache;
map<const unsigned int, searchable_list< [[[$nonterminal]]]* > > [[[$nonterminal]]]::m_active_terminals;
#endif // DISABLE_GENERATED_STRING_CACHING_OPTIMIZATION
[[[
foreach my $i (1..$#productions+1)
{
    $OUT .=<<EOF;

// ---------------------------------------------------------------------------

class ${nonterminal}::match_$i : public Rule_List
{
  friend class $nonterminal;
EOF

    $OUT .= "\n  $return_type dollar_dollar;\n"
      if defined $return_type;

    # -----------------------------------------------------------
    # Constructor

    $OUT .=<<EOF;

  match_$i()
  {
EOF

    $OUT .= "    dollar_dollar = new $nonpointer_return_type;\n\n"
      if defined $nonpointer_return_type;

    foreach my $rule (@{$productions[$i-1]{'rules'}})
    {
      $OUT .= "    push_back(new $rule);\n";
    }

    $OUT .=<<EOF;
  }
EOF

    # -----------------------------------------------------------
    # Destructor

    if (defined $nonpointer_return_type)
    {
      $OUT .=<<EOF;

  ~match_$i()
  {
    delete dollar_dollar;
  }
EOF
    }

    # -----------------------------------------------------------
    # Do_Action

    if(defined $productions[$i-1]{'action code'})
    {
      $OUT .=<<EOF;

  void Do_Action()
  {
EOF

      $OUT .= "    $return_type old_dollar_dollar = dollar_dollar;\n"
        if defined $nonpointer_return_type;

      $OUT .= $productions[$i-1]{'action code'} . "\n";

      $OUT .= "\n    if (dollar_dollar != old_dollar_dollar)\n" .
              "      delete old_dollar_dollar;\n"
        if defined $nonpointer_return_type;

      $OUT .=<<EOF;
  }
EOF
    }

    # -----------------------------------------------------------
    # Undo_Action

    if(defined $productions[$i-1]{'unaction code'})
    {
      $OUT .=<<EOF;

  void Undo_Action()
  {
$productions[$i-1]{'unaction code'}
  }
EOF
    }

    # -----------------------------------------------------------
    # Get_Value

    if (defined $return_type)
    {
      $OUT .=<<EOF;

  const $return_type Get_Value() const
  {
    return dollar_dollar;
  }
EOF

    }
    $OUT .=<<EOF;

};
EOF
}
]]]
// ---------------------------------------------------------------------------

[[[$nonterminal]]]::[[[$nonterminal]]]() : Nonterminal_Rule()
{
[[[
  foreach my $i (1..$#productions+1)
  {
    $OUT .= "  m_$i = NULL;\n";
  }
]]]}

// ---------------------------------------------------------------------------

[[[$nonterminal]]]::~[[[$nonterminal]]]()
{
[[[
  foreach my $i (1..$#productions+1)
  {
    $OUT .= <<EOF;
  if (m_$i != NULL)
    delete m_$i;
EOF
  }
]]]}

// ---------------------------------------------------------------------------

void [[[$nonterminal]]]::Initialize(const unsigned int in_allowed_length, const Rule *in_previous_rule)
{
  m_rule_lists.clear();
[[[
  foreach my $i (1..$#productions+1)
  {
    my $operator = $productions[$i-1]{'length constraint'} =~ /^=/ ? '==' : '>=';
    my ($number) = $productions[$i-1]{'length constraint'} =~ /(\d+)/;

    $OUT .=<<"EOF";

#ifndef DISABLE_PRODUCTION_LENGTH_OPTIMIZATION
  if (in_allowed_length $operator $number)
#endif // DISABLE_PRODUCTION_LENGTH_OPTIMIZATION
  {
    if (m_$i == NULL)
      m_$i = new match_$i;

    m_rule_lists.push_back(m_$i);
  }
EOF
  }

  $OUT .= "\n  Nonterminal_Rule::Initialize(in_allowed_length, in_previous_rule);\n";
  $OUT .= "}\n";

  if (defined $return_type)
  {
    $OUT .=<<EOF;

// ---------------------------------------------------------------------------

const $return_type ${nonterminal}::Get_Value()
EOF
    $OUT .= "{\n";
    $OUT .=<<EOF;
  Set_Accessed(true);

EOF

    foreach my $i (1..$#productions+1)
    {
      $OUT .=<<EOF;
  if (match_$i* the_rule_list = dynamic_cast<match_$i*>(*m_current_rule_list))
    return the_rule_list->Get_Value();

EOF
    }

    $OUT .= "  assert(false);\n\n";

    if (defined $nonpointer_return_type)
    {
      $OUT .= "  return new $nonpointer_return_type();\n";
    }
    else
    {
      $OUT .= "  return $return_type();\n";
    }

    $OUT .= "}\n";
  }

  chomp $OUT;
]]]
// ---------------------------------------------------------------------------

void [[[$nonterminal]]]::Reset_String()
{
#ifndef DISABLE_GENERATED_STRING_CACHING_OPTIMIZATION
  if (m_generated_cache.find(m_allowed_length) != m_generated_cache.end())
  {
#ifdef SHORT_RULE_TRACE
    cerr << "RESET: " << Utility::indent << "Nonterminal: " <<
      Utility::readable_type_name(typeid(*this)) <<
      "(" << m_allowed_length << ") [Resetting cache pointer]" << endl;
#endif // SHORT_RULE_TRACE

    m_current_string_list = m_generated_cache[m_allowed_length].begin();

    m_using_cache = true;
    m_first_cache_string = true;

    return;
  }

  m_using_cache = false;

  // Since Reset_String will be called for each terminal of this kind, the
  // last one will be the one that will be incremented first.
  if (m_active_terminals[m_allowed_length].find(this) ==
      m_active_terminals[m_allowed_length].end())
    m_active_terminals[m_allowed_length].push_back(this);
#endif // DISABLE_GENERATED_STRING_CACHING_OPTIMIZATION

  Nonterminal_Rule::Reset_String();
}

// ---------------------------------------------------------------------------

const bool [[[$nonterminal]]]::Check_For_String()
{
#ifndef DISABLE_GENERATED_STRING_CACHING_OPTIMIZATION
  // We check m_using_cache in case this terminal was in the middle of
  // generating when a later one finished generating and cached its results.
  if (m_generated_cache.find(m_allowed_length) != m_generated_cache.end() &&
      m_using_cache)
  {
#ifdef SHORT_RULE_TRACE
    cerr << "CHECK: " << Utility::indent << "Nonterminal: " <<
      Utility::readable_type_name(typeid(*this)) << "(" << m_allowed_length <<
      ") [Checking cache]" << endl;
#endif // SHORT_RULE_TRACE

    if (!m_first_cache_string &&
        m_current_string_list != m_generated_cache[m_allowed_length].end())
      m_current_string_list++;

    m_first_cache_string = false;

    if (m_current_string_list != m_generated_cache[m_allowed_length].end())
    {
#ifdef SHORT_RULE_TRACE
      cerr << "CHECK: " << Utility::indent <<
        "--> NONTERMINAL VALID [Using cached string]" << endl;
#endif // SHORT_RULE_TRACE

      return true;
    }
    else
    {
#ifdef SHORT_RULE_TRACE
      cerr << "CHECK: " << Utility::indent <<
        "--> NONTERMINAL NOT VALID [No cached strings]" << endl;
#endif // SHORT_RULE_TRACE

      return false;
    }
  }

  if (m_active_terminals[m_allowed_length].size() > 0 &&
      m_active_terminals[m_allowed_length].back() == this)
  {
    const bool more_strings = Nonterminal_Rule::Check_For_String();

    if (more_strings)
    {
      m_intermediate_cache[m_allowed_length].push_back(
        Nonterminal_Rule::Get_String());
    }
    else
    {
#ifdef SHORT_RULE_TRACE
      cerr << "CHECK: " << Utility::indent <<
        "--> NONTERMINAL NOT VALID [Caching generated strings]" << endl;
#endif // SHORT_RULE_TRACE

      m_generated_cache[m_allowed_length] =
        m_intermediate_cache[m_allowed_length];

      m_intermediate_cache[m_allowed_length].clear();
      m_active_terminals.erase(m_allowed_length);
    }

    return more_strings;
  }
#endif // DISABLE_GENERATED_STRING_CACHING_OPTIMIZATION

  return Nonterminal_Rule::Check_For_String();
}

// ---------------------------------------------------------------------------

const list<string>& [[[$nonterminal]]]::Get_String() const
{
#ifndef DISABLE_GENERATED_STRING_CACHING_OPTIMIZATION
  // We check m_using_cache in case this terminal was in the middle of
  // generating when a later one finished generating and cached its results.
  if (m_generated_cache.find(m_allowed_length) != m_generated_cache.end() &&
      m_using_cache)
    return *m_current_string_list;
#endif // DISABLE_GENERATED_STRING_CACHING_OPTIMIZATION

  return Nonterminal_Rule::Get_String();
}
