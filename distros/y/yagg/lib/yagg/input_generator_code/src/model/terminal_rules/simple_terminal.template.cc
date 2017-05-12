#include "model/terminal_rules/[[[$terminal]]].h"
[[[
if ($return_type ne 'string' ||
    defined $nonpointer_return_type && $nonpointer_return_type ne 'string')
{
  $OUT .= "#include <sstream>";
}
]]]
#include <list>

using namespace std;

// ---------------------------------------------------------------------------

[[[$terminal]]]::[[[$terminal]]]()
{
  return_value = [[[ $strings[0] ]]];

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

chomp $OUT;
]]]
}

// ---------------------------------------------------------------------------

const bool [[[$terminal]]]::Check_For_String()
{
  m_string_count++;

  if (m_string_count > 1)
    return false;

  if (!Is_Valid())
    return false;

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
