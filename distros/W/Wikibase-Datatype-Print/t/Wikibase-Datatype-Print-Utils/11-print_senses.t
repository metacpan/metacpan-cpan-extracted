use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Lexeme::Wikidata::DogCzechNoun;
use Unicode::UTF8 qw(decode_utf8);
use Wikibase::Datatype::Print::Utils qw(print_senses);
use Wikibase::Datatype::Print::Sense;

# Test.
my $obj = Test::Shared::Fixture::Wikibase::Datatype::Lexeme::Wikidata::DogCzechNoun->new;
my @ret = print_senses($obj, {},
	\&Wikibase::Datatype::Print::Sense::print);
is_deeply(
	\@ret,
	[
		'Senses:',
		'  Id: L469-S1',
		'  Glosses:',
		'    domesticated mammal related to the wolf (en)',
		decode_utf8('    psovitá šelma chovaná jako domácí zvíře (cs)'),
		'  Statements:',
		'    P18: Canadian Inuit Dog.jpg (normal)',
		'    P5137: Q144 (normal)',
	],
	'Print senses test.',
);
