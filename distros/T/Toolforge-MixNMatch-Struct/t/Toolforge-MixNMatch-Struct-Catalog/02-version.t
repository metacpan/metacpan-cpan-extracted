use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Toolforge::MixNMatch::Struct::Catalog;

# Test.
is($Toolforge::MixNMatch::Struct::Catalog::VERSION, 0.04, 'Version.');
