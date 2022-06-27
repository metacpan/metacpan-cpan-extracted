use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Form::Wikidata::DogCzechSingular;

# Test.
my $obj = Test::Shared::Fixture::Wikibase::Datatype::Form::Wikidata::DogCzechSingular->new;
isa_ok($obj, 'Test::Shared::Fixture::Wikibase::Datatype::Form::Wikidata::DogCzechSingular');
