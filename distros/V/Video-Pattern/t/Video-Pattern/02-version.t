use strict;
use warnings;

use Video::Pattern;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Video::Pattern::VERSION, 0.09, 'Version.');
