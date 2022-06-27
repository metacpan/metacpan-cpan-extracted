use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Lexeme::Wikidata::DogCzechNoun;
use Wikibase::Datatype::Lexeme;

# Test.
my $obj = Wikibase::Datatype::Lexeme->new;
my $ret_ar = $obj->statements;
is_deeply(
	$ret_ar,
	[],
	'Get default staments.',
);

# Test.
$obj = Test::Shared::Fixture::Wikibase::Datatype::Lexeme::Wikidata::DogCzechNoun->new;
$ret_ar = $obj->statements;
is(@{$ret_ar}, 2, 'Get number of statements.');
