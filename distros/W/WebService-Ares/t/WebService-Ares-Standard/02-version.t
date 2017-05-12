# Pragmas.
use strict;
use warnings;

# Modules.
use WebService::Ares::Standard;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($WebService::Ares::Standard::VERSION, 0.02, 'Version.');
