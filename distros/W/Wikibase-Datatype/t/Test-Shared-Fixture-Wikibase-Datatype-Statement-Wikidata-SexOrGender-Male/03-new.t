use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::SexOrGender::Male;

# Test.
my $obj = Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::SexOrGender::Male->new;
isa_ok($obj, 'Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::SexOrGender::Male');
