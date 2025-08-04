use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Struct::Term;

# Test.
is($Wikibase::Datatype::Struct::Term::VERSION, 0.15, 'Version.');
