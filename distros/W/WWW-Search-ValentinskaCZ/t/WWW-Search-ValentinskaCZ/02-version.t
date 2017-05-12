# Pragmas.
use strict;
use warnings;

# Modules.
use WWW::Search::ValentinskaCZ;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($WWW::Search::ValentinskaCZ::VERSION, 0.03, 'Version.');
