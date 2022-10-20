use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::SexOrGender::Male;

# Test.
is($Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::SexOrGender::Male::VERSION, 0.22, 'Version.');
