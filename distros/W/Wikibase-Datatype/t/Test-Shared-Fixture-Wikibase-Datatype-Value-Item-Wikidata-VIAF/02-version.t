use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Value::Item::Wikidata::VIAF;

# Test.
is($Test::Shared::Fixture::Wikibase::Datatype::Value::Item::Wikidata::VIAF::VERSION, 0.34, 'Version.');
