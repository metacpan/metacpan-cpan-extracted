use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::Retrieved::Fixture1;

# Test.
is($Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::Retrieved::Fixture1::VERSION, 0.24, 'Version.');
