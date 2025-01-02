use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Value::Item::Wikidata::Poem;

# Test.
is($Test::Shared::Fixture::Wikibase::Datatype::Value::Item::Wikidata::Poem::VERSION, 0.36, 'Version.');
