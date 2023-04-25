use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::InstanceOf::Human;

# Test.
is($Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::InstanceOf::Human::VERSION, 0.29, 'Version.');
