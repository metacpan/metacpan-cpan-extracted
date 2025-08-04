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
my $ret = $obj->query_lexeme($item, 'P5185');
is($ret, 'Q499327', 'Get Lexeme P5185 value in scalar context (Q499327).');

# Test.
$obj = Wikibase::Datatype::Query->new;
my @ret = $obj->query_lexeme($item, 'P5185');
is_deeply(\@ret, ['Q499327'], 'Get Lexeme P5185 value in array context (Q499327).');
