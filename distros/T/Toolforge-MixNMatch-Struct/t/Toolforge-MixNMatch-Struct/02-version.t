use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Toolforge::MixNMatch::Struct;

# Test.
is($Toolforge::MixNMatch::Struct::VERSION, 0.04, 'Version.');
