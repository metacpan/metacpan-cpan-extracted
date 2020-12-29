use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Toolforge::MixNMatch::Diff;

# Test.
is($Toolforge::MixNMatch::Diff::VERSION, 0.02, 'Version.');
