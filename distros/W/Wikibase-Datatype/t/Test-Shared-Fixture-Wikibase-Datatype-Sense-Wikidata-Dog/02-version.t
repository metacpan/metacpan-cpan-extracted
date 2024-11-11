use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Sense::Wikidata::Dog;

# Test.
is($Test::Shared::Fixture::Wikibase::Datatype::Sense::Wikidata::Dog::VERSION, 0.34, 'Version.');
