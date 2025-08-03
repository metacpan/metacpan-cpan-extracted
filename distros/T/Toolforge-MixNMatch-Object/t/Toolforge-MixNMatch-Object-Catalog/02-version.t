use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Toolforge::MixNMatch::Object::Catalog;

# Test.
is($Toolforge::MixNMatch::Object::Catalog::VERSION, 0.04, 'Version.');
