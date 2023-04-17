use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::GrammaticalGender::Masculine;

# Test.
is($Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::GrammaticalGender::Masculine::VERSION, 0.25, 'Version.');
