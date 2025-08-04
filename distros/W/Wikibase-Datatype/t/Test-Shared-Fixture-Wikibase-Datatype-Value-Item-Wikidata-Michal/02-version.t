use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Value::Item::Wikidata::Michal;

# Test.
is($Test::Shared::Fixture::Wikibase::Datatype::Value::Item::Wikidata::Michal::VERSION, 0.39, 'Version.');
