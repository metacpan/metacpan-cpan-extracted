use strict;
use warnings;

use Test::More 'tests' => 4;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Lexeme::Wikidata::DogCzechNoun;
use Wikibase::Datatype::Lexeme;

# Test.
my $obj = Wikibase::Datatype::Lexeme->new;
my $ret_ar = $obj->senses;
is_deeply(
	$ret_ar,
	[],
	'Get default senses.',
);

# Test.
$obj = Test::Shared::Fixture::Wikibase::Datatype::Lexeme::Wikidata::DogCzechNoun->new;
$ret_ar = $obj->senses;
is(@{$ret_ar}, 1, 'Get number of senses.');
is($ret_ar->[0]->id, 'L469-S1', 'Id of sense.');
