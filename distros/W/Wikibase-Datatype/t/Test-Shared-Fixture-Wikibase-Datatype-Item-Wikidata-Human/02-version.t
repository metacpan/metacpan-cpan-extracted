use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Human;

# Test.
is($Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Human::VERSION, undef, 'Version.');
