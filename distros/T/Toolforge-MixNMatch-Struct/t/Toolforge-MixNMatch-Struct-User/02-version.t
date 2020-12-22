use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Toolforge::MixNMatch::Struct::User;

# Test.
is($Toolforge::MixNMatch::Struct::User::VERSION, 0.04, 'Version.');
