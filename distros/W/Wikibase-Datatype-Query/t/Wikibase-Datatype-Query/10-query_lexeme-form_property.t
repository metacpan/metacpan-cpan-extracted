use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Lexeme::Wikidata::DogCzechNoun 0.19;
use Wikibase::Datatype::Query;
use Unicode::UTF8 qw(decode_utf8);

# Common.
my $item = Test::Shared::Fixture::Wikibase::Datatype::Lexeme::Wikidata::DogCzechNoun->new;

# Test.
my $obj = Wikibase::Datatype::Query->new;
my $ret = $obj->query_lexeme($item, 'form:P898');
is($ret, decode_utf8('pɛs'), 'Get Lexeme form P898 value in scalar context (pɛs).');

# Test.
$obj = Wikibase::Datatype::Query->new;
my @ret = $obj->query_lexeme($item, 'form:P898');
is_deeply(\@ret, [decode_utf8('pɛs')], 'Get Lexeme form P898 value in array context (pɛs).');
