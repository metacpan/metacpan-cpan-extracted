# Pragmas.
use strict;
use warnings;

# Modules.
use WWW::Search::Antikvariat11CZ;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($WWW::Search::Antikvariat11CZ::VERSION, 0.01, 'Version.');
