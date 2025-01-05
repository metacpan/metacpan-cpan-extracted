use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::GivenName::Michal;

# Test.
is($Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::GivenName::Michal::VERSION, 0.37, 'Version.');
