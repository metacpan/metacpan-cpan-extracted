use strict;
use warnings;

use Test::More 'tests' => 5;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Lexeme::Wikidata::DogCzechNoun;
use Wikibase::Datatype::Lexeme;

# Test.
my $obj = Wikibase::Datatype::Lexeme->new;
my $ret_ar = $obj->lemmas;
is_deeply(
	$ret_ar,
	[],
	'Get default lemmas.',
);

# Test.
$obj = Test::Shared::Fixture::Wikibase::Datatype::Lexeme::Wikidata::DogCzechNoun->new;
$ret_ar = $obj->lemmas;
is(@{$ret_ar}, 1, 'Get number of lemmas.');
is($ret_ar->[0]->value, 'pes', 'Get value of lemma.');
is($ret_ar->[0]->language, 'cs', 'Get language of lemma.');
