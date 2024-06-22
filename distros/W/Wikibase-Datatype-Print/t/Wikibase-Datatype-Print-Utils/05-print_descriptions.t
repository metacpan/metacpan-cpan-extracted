use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Dog;
use Unicode::UTF8 qw(decode_utf8);
use Wikibase::Datatype::Print::Texts qw(texts);
use Wikibase::Datatype::Print::Utils qw(print_descriptions);
use Wikibase::Datatype::Print::Value::Monolingual;

# Test.
my $obj = Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Dog->new;
my @ret = print_descriptions($obj, { 'lang' => 'en', 'texts' => texts() },
	\&Wikibase::Datatype::Print::Value::Monolingual::print);
is_deeply(
	\@ret,
	[
		'Description: domestic animal (en)',
	],
	'Print description test.',
);
