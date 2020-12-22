use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Toolforge::MixNMatch::Object;

# Test.
is($Toolforge::MixNMatch::Object::VERSION, 0.03, 'Version.');
