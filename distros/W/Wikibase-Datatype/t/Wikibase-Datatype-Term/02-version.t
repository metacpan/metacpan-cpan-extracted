use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Term;

# Test.
is($Wikibase::Datatype::Term::VERSION, 0.39, 'Version.');
