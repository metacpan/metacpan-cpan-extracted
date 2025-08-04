use strict;
use warnings;

use Test::More 'tests' => 4;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Dog;
use Unicode::UTF8 qw(decode_utf8);
use Wikibase::Datatype::Print::Term;
use Wikibase::Datatype::Print::Texts qw(texts);
use Wikibase::Datatype::Print::Utils qw(print_descriptions);

# Test.
my $obj = Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Dog->new;
my @ret = print_descriptions($obj, { 'lang' => 'en', 'texts' => texts() },
	\&Wikibase::Datatype::Print::Term::print);
is_deeply(
	\@ret,
	[
		'Description: domestic animal (en)',
	],
	'Print description test (one language, lang is en).',
);

# Test.
$obj = Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Dog->new;
@ret = print_descriptions($obj, { 'lang' => '', 'texts' => texts() },
	\&Wikibase::Datatype::Print::Term::print);
is_deeply(
	\@ret,
	[
		'Description:',
		decode_utf8('  domácí zvíře (cs)'),
		'  domestic animal (en)',
	],
	'Print description test (all languages, lang is blank string).',
);

# Test.
$obj = Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Dog->new;
@ret = print_descriptions($obj, { 'texts' => texts() },
	\&Wikibase::Datatype::Print::Term::print);
is_deeply(
	\@ret,
	[
		'Description:',
		decode_utf8('  domácí zvíře (cs)'),
		'  domestic animal (en)',
	],
	'Print description test (all languages, lang is not defined).',
);
