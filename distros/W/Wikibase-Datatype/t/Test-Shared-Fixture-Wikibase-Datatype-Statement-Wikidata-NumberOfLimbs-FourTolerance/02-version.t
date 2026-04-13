use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::NumberOfLimbs::FourTolerance;

# Test.
is($Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::NumberOfLimbs::FourTolerance::VERSION, 0.4, 'Version.');
