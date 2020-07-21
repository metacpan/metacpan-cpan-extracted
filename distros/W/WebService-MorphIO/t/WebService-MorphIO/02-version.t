use strict;
use warnings;

use WebService::MorphIO;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($WebService::MorphIO::VERSION, 0.04, 'Version.');
