package t::Sample::IgnoreWarnings;

use t::ToolSet::Null;

my $var = "";
$var = $var + 1; # shouldn't warn

1;               # return true
