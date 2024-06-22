use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Form::Wikidata::DogCzechSingular;
use Unicode::UTF8 qw(decode_utf8);
use Wikibase::Datatype::Print::Texts qw(texts);
use Wikibase::Datatype::Print::Utils qw(print_statements);
use Wikibase::Datatype::Print::Statement;

# Test.
my $obj = Test::Shared::Fixture::Wikibase::Datatype::Form::Wikidata::DogCzechSingular->new;
my @ret = print_statements($obj, { 'texts' => texts() },
	\&Wikibase::Datatype::Print::Statement::print);
is_deeply(
	\@ret,
	[
		'Statements:',
		decode_utf8('  P898: pɛs (normal)'),
	],
	'Print statements test.',
);
