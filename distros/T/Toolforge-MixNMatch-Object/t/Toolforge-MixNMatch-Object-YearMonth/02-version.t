use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Toolforge::MixNMatch::Object::YearMonth;

# Test.
is($Toolforge::MixNMatch::Object::YearMonth::VERSION, 0.04, 'Version.');
