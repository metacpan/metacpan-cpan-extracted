package t::Sample::NoStrictRefs;

use t::ToolSet::NoStrictRefs;

our $var = 42;

my $name = "var";
${$name}++; # OK with no strict refs

$pi = 3.14; # Should fails under strict

1;          # return true
