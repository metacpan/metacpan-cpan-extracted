# Pragmas.
use strict;
use warnings;

# Modules.
use WWW::Search::AntikvariatJudaicaCZ;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($WWW::Search::AntikvariatJudaicaCZ::VERSION, 0.02, 'Version.');
