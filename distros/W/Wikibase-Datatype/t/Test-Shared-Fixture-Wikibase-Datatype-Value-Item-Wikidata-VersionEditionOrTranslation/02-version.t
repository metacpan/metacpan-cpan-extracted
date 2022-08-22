use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Value::Item::Wikidata::VersionEditionOrTranslation;

# Test.
is($Test::Shared::Fixture::Wikibase::Datatype::Value::Item::Wikidata::VersionEditionOrTranslation::VERSION, 0.2, 'Version.');
