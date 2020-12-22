use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Toolforge::MixNMatch::Struct::YearMonth;

# Test.
is($Toolforge::MixNMatch::Struct::YearMonth::VERSION, 0.04, 'Version.');
