use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::ItemForThisSense::Dog;

# Test.
is($Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::ItemForThisSense::Dog::VERSION, 0.22, 'Version.');
