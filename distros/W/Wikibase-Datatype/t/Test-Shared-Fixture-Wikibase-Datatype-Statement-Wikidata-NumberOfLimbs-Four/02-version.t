use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::NumberOfLimbs::Four;

# Test.
is($Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::NumberOfLimbs::Four::VERSION, 0.38, 'Version.');
