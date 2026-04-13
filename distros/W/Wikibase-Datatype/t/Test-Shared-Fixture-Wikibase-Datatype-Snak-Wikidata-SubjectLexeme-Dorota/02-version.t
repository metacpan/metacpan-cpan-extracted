use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::SubjectLexeme::Dorota;

# Test.
is($Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::SubjectLexeme::Dorota::VERSION, 0.4, 'Version.');
