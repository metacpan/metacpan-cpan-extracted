use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Print::Term;

# Test.
is($Wikibase::Datatype::Print::Term::VERSION, 0.2, 'Version.');
