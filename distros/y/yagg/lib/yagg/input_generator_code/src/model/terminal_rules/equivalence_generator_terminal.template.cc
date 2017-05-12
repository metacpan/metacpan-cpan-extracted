#include "model/terminal_rules/[[[$terminal]]].h"
#include <sstream>
#include <list>
#include <map>

using namespace std;

// ---------------------------------------------------------------------------

const bool [[[$terminal]]]::Check_For_String()
{
  if (!Is_Valid())
    return false;

  static map<unsigned int, unsigned int> counts;

  if (counts.find(m_string_count) != counts.end())
  {
    if (counts[m_string_count] == 1)
      counts.erase(m_string_count);
    else
      counts[m_string_count]--;
  }

  m_string_count++;

  if (m_string_count > counts.size() + 1)
    return false;

  counts[m_string_count]++;

[[[
my ($prefix,$suffix) = $strings[0] =~ /^['"](.*(?<!\\))#(.*)["']$/;
$OUT .= "  stringstream temp_stream;\n\n";
$OUT .= "  temp_stream";
$OUT .= " << \"$prefix\"" if $prefix ne '';
$OUT .= " << m_string_count";
$OUT .= " << \"$suffix\"" if $suffix ne '';
$OUT .= ";\n";

$OUT .= "  return_value = temp_stream.str();";
]]]

  strings.clear();

  strings.push_back(return_value);

  return true;
}

// ---------------------------------------------------------------------------

const list<string>& [[[$terminal]]]::Get_String() const
{
  return strings;
}

// ---------------------------------------------------------------------------

[[[
if (defined $nonpointer_return_type)
{
  $OUT .= <<EOF;
const $return_type ${terminal}::Get_Value()
{
  Set_Accessed(true);

  return &return_value;
}
EOF
}
else
{
  $OUT .= <<EOF;
const $return_type& ${terminal}::Get_Value()
{
  Set_Accessed(true);

  return return_value;
}
EOF
}

chomp $OUT;
]]]
