package t::Sample::HasWarnings;

use t::ToolSet::StrictWarn;

my $var = "";
$var = $var + 1; # should warn

1;               # return true
