use strict;
use warnings;

use Test::More 'tests' => 4;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Lexeme::Wikidata::DogCzechNoun;
use Wikibase::Datatype::Lexeme;

# Test.
my $obj = Wikibase::Datatype::Lexeme->new;
my $ret_ar = $obj->forms;
is_deeply(
	$ret_ar,
	[],
	'Get reference to blank array of forms.',
);

# Test.
$obj = Test::Shared::Fixture::Wikibase::Datatype::Lexeme::Wikidata::DogCzechNoun->new;
$ret_ar = $obj->forms;
is(@{$ret_ar}, 1, 'Get number of forms.');
is($ret_ar->[0]->id, 'L469-F1', 'Get id of form.');
