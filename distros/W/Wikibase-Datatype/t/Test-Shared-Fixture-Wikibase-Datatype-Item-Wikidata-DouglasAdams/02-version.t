use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::DouglasAdams;

# Test.
is($Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::DouglasAdams::VERSION, 0.16, 'Version.');
