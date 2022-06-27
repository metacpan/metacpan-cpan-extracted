use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Reference::Wikidata::Fixture1;

# Test.
is($Test::Shared::Fixture::Wikibase::Datatype::Reference::Wikidata::Fixture1::VERSION, 0.16, 'Version.');
