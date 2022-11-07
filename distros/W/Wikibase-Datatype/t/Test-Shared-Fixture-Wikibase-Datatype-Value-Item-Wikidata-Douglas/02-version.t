use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Value::Item::Wikidata::Douglas;

# Test.
is($Test::Shared::Fixture::Wikibase::Datatype::Value::Item::Wikidata::Douglas::VERSION, 0.23, 'Version.');
