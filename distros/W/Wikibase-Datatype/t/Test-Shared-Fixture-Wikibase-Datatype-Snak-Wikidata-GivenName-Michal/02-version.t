use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::GivenName::Michal;

# Test.
is($Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::GivenName::Michal::VERSION, 0.36, 'Version.');
