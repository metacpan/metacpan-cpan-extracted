use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Value::Item::Wikidata::WikidataEntity;

# Test.
my $obj = Test::Shared::Fixture::Wikibase::Datatype::Value::Item::Wikidata::WikidataEntity->new;
isa_ok($obj, 'Test::Shared::Fixture::Wikibase::Datatype::Value::Item::Wikidata::WikidataEntity');
