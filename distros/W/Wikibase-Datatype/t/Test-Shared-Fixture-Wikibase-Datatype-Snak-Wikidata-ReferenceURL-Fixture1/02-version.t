use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::ReferenceURL::Fixture1;

# Test.
is($Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::ReferenceURL::Fixture1::VERSION, 0.01, 'Version.');
