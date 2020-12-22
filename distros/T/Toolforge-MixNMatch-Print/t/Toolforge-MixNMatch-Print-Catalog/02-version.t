use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Toolforge::MixNMatch::Print::Catalog;

# Test.
is($Toolforge::MixNMatch::Print::Catalog::VERSION, 0.03, 'Version.');
