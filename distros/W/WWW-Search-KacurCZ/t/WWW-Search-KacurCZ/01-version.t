# Pragmas.
use strict;
use warnings;

# Modules.
use WWW::Search::KacurCZ;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($WWW::Search::KacurCZ::VERSION, 0.01, 'Version.');
