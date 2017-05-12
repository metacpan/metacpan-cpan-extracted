package t::Sample::NotStrictError;

use t::ToolSet::StrictWarn;

$var = 42;
$var++;

1; # return true
