use strict;
use warnings;

use Test::More 'tests' => 4;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Dog;
use Unicode::UTF8 qw(decode_utf8);
use Wikibase::Datatype::Print::Texts qw(texts);
use Wikibase::Datatype::Print::Utils qw(print_labels);
use Wikibase::Datatype::Print::Value::Monolingual;

# Test.
my $obj = Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Dog->new;
my @ret = print_labels($obj, { 'lang' => 'en', 'texts' => texts() },
	\&Wikibase::Datatype::Print::Value::Monolingual::print);
is_deeply(
	\@ret,
	[
		'Label: dog (en)',
	],
	'Print labels test (en).',
);

# Test.
$obj = Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Dog->new;
@ret = print_labels($obj, { 'lang' => '', 'texts' => texts() },
	\&Wikibase::Datatype::Print::Value::Monolingual::print);
is_deeply(
	\@ret,
	[
		'Label:',
		'  pes (cs)',
		'  dog (en)',
	],
	'Print labels test (all languages, lang is blank string).',
);

# Test.
$obj = Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Dog->new;
@ret = print_labels($obj, { 'texts' => texts() },
	\&Wikibase::Datatype::Print::Value::Monolingual::print);
is_deeply(
	\@ret,
	[
		'Label:',
		'  pes (cs)',
		'  dog (en)',
	],
	'Print labels test (all languages, lang is undefined).',
);
