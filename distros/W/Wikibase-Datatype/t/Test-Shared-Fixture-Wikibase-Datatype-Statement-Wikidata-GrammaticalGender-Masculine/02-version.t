use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::GrammaticalGender::Masculine;

# Test.
is($Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::GrammaticalGender::Masculine::VERSION, 0.39, 'Version.');
