use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Reference::Wikidata::VIAF;

# Test.
is($Test::Shared::Fixture::Wikibase::Datatype::Reference::Wikidata::VIAF::VERSION, 0.25, 'Version.');
