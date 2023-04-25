use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Value::Item::Wikidata::WikidataEntity;

# Test.
is($Test::Shared::Fixture::Wikibase::Datatype::Value::Item::Wikidata::WikidataEntity::VERSION, 0.29, 'Version.');
