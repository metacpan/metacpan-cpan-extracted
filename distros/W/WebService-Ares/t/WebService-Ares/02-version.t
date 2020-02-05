use strict;
use warnings;

use WebService::Ares;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($WebService::Ares::VERSION, 0.03, 'Version.');
