use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Value::Item::Wikidata::DouglasAdams;

# Test.
my $obj = Test::Shared::Fixture::Wikibase::Datatype::Value::Item::Wikidata::DouglasAdams->new;
isa_ok($obj, 'Test::Shared::Fixture::Wikibase::Datatype::Value::Item::Wikidata::DouglasAdams');
