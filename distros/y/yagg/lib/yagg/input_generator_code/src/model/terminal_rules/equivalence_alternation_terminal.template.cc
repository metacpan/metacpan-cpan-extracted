#include "model/terminal_rules/[[[$terminal]]].h"
[[[
if ($return_type ne 'string' ||
    defined $nonpointer_return_type && $nonpointer_return_type ne 'string')
{
  $OUT .= "#include <sstream>";
}
]]]
#include <cassert>
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

  if (m_string_count > counts.size() + 1 || m_string_count > [[[$size]]])
    return false;

  counts[m_string_count]++;

  switch (m_string_count)
  {
[[[
for (my $i = 1; $i-1 < $size; $i++)
{
  $OUT .=<<"EOF";
    case $i :
    {
      return_value = $strings[$i-1];
      break;
    }
EOF
}
]]]
  }

  strings.clear();

[[[
if ($return_type ne 'string' ||
    defined $nonpointer_return_type && $nonpointer_return_type ne 'string')
{
  $OUT .= <<EOF;
  stringstream temp_stream;
  temp_stream << return_value;

  strings.push_back(temp_stream.str());
EOF
}
else
{
  $OUT .= <<EOF;
  strings.push_back(return_value);
EOF
}
]]]
  return true;
}

// ---------------------------------------------------------------------------

const list<string>& [[[$terminal]]]::Get_String() const
{
  assert(m_string_count <= [[[$size]]]);

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
