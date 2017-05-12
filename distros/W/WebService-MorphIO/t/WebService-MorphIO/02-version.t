# Pragmas.
use strict;
use warnings;

# Modules.
use WebService::MorphIO;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($WebService::MorphIO::VERSION, 0.03, 'Version.');
