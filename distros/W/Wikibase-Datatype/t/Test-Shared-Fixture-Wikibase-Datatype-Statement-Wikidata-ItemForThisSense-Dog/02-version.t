use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::ItemForThisSense::Dog;

# Test.
is($Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::ItemForThisSense::Dog::VERSION, 0.33, 'Version.');
