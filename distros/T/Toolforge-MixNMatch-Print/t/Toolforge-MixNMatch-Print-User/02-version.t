use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Toolforge::MixNMatch::Print::User;

# Test.
is($Toolforge::MixNMatch::Print::User::VERSION, 0.04, 'Version.');
