use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Value::Item::Wikidata::FemaleGivenName;

# Test.
is($Test::Shared::Fixture::Wikibase::Datatype::Value::Item::Wikidata::FemaleGivenName::VERSION, 0.33, 'Version.');
