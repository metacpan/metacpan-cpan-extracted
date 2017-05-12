# Pragmas.
use strict;
use warnings;

# Modules.
use WWW::Search::GalerieIlonkaCZ;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($WWW::Search::GalerieIlonkaCZ::VERSION, 0.01, 'Version.');
