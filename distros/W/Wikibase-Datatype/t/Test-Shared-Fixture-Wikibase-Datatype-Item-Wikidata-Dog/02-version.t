use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Dog;

# Test.
is($Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Dog::VERSION, 0.37, 'Version.');
