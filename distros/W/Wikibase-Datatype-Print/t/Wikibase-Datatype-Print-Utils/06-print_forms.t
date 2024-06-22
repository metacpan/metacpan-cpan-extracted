use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Lexeme::Wikidata::DogCzechNoun;
use Unicode::UTF8 qw(decode_utf8);
use Wikibase::Datatype::Print::Texts qw(texts);
use Wikibase::Datatype::Print::Utils qw(print_forms);
use Wikibase::Datatype::Print::Form;

# Test.
my $obj = Test::Shared::Fixture::Wikibase::Datatype::Lexeme::Wikidata::DogCzechNoun->new;
my @ret = print_forms($obj, { 'texts' => texts() },
	\&Wikibase::Datatype::Print::Form::print);
is_deeply(
	\@ret,
	[
		'Forms:',
		'  Id: L469-F1',
		'  Representation: pes (cs)',
		'  Grammatical features: Q110786, Q131105',
		'  Statements:',
		decode_utf8('    P898: pɛs (normal)'),
	],
	'Print forms test.',
);
