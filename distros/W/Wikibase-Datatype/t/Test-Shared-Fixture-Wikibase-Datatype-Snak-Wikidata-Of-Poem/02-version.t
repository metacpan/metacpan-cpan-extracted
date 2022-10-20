use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::Of::Poem;

# Test.
is($Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::Of::Poem::VERSION, 0.22, 'Version.');
