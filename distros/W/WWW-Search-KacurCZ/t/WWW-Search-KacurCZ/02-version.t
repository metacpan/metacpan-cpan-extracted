use strict;
use warnings;

use WWW::Search::KacurCZ;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($WWW::Search::KacurCZ::VERSION, 0.02, 'Version.');
