use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Value::Item::Wikidata::Male;

# Test.
my $obj = Test::Shared::Fixture::Wikibase::Datatype::Value::Item::Wikidata::Male->new;
isa_ok($obj, 'Test::Shared::Fixture::Wikibase::Datatype::Value::Item::Wikidata::Male');
