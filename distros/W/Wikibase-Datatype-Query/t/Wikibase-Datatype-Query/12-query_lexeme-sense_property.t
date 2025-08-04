use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Lexeme::Wikidata::DogCzechNoun 0.19;
use Wikibase::Datatype::Query;

# Common.
my $item = Test::Shared::Fixture::Wikibase::Datatype::Lexeme::Wikidata::DogCzechNoun->new;

# Test.
my $obj = Wikibase::Datatype::Query->new;
my $ret = $obj->query_lexeme($item, 'sense:P18');
is($ret, 'Canadian Inuit Dog.jpg', 'Get Lexeme sense P18 value in scalar context (Canadian Inuit Dog.jpg).');

# Test.
$obj = Wikibase::Datatype::Query->new;
my @ret = $obj->query_lexeme($item, 'sense:P18');
is_deeply(\@ret, ['Canadian Inuit Dog.jpg'], 'Get Lexeme sense P18 value in array context (Canadian Inuit Dog.jpg).');
