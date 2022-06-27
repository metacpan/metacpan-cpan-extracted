use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Reference::Wikidata::ReferenceURL;

# Test.
is($Test::Shared::Fixture::Wikibase::Datatype::Reference::Wikidata::ReferenceURL::VERSION, 0.16, 'Version.');
