use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::InstanceOf::Human;

# Test.
is($Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::InstanceOf::Human::VERSION, 0.31, 'Version.');
