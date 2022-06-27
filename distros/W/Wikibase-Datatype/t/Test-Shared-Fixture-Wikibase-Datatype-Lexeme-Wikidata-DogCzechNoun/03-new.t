use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Lexeme::Wikidata::DogCzechNoun;

# Test.
my $obj = Test::Shared::Fixture::Wikibase::Datatype::Lexeme::Wikidata::DogCzechNoun->new;
isa_ok($obj, 'Test::Shared::Fixture::Wikibase::Datatype::Lexeme::Wikidata::DogCzechNoun');
