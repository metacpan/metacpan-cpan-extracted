use strict;
use warnings;

use WebService::Ares::Standard;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($WebService::Ares::Standard::VERSION, 0.03, 'Version.');
