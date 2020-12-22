use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Toolforge::MixNMatch::Print::YearMonth;

# Test.
is($Toolforge::MixNMatch::Print::YearMonth::VERSION, 0.03, 'Version.');
