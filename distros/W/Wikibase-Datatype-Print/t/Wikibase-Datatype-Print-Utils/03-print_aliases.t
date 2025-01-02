use strict;
use warnings;

use Test::More 'tests' => 5;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Dog;
use Unicode::UTF8 qw(decode_utf8);
use Wikibase::Datatype::Print::Texts qw(texts);
use Wikibase::Datatype::Print::Utils qw(print_aliases);
use Wikibase::Datatype::Print::Value::Monolingual;

# Test.
my $obj = Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Dog->new;
my @ret = print_aliases($obj, { 'lang' => 'cs', 'texts' => texts() },
	\&Wikibase::Datatype::Print::Value::Monolingual::print);
is_deeply(
	\@ret,
	[
		'Aliases:',
		decode_utf8('  pes domácí (cs)'),
	],
	'Print aliases test (cs).',
);

# Test.
$obj = Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Dog->new;
@ret = print_aliases($obj, { 'lang' => 'en', 'texts' => texts() },
	\&Wikibase::Datatype::Print::Value::Monolingual::print);
is_deeply(
	\@ret,
	[
		'Aliases:',
		'  domestic dog (en)',
		'  Canis lupus familiaris (en)',
		'  Canis familiaris (en)',
		'  dogs (en)',
		decode_utf8('  🐶 (en)'),
		decode_utf8('  🐕 (en)'),
	],
	'Print aliases test (en).',
);

# Test.
$obj = Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Dog->new;
@ret = print_aliases($obj, { 'lang' => '', 'texts' => texts() },
	\&Wikibase::Datatype::Print::Value::Monolingual::print);
is_deeply(
	\@ret,
	[
		'Aliases:',
		decode_utf8('  pes domácí (cs)'),
		'  domestic dog (en)',
		'  Canis lupus familiaris (en)',
		'  Canis familiaris (en)',
		'  dogs (en)',
		decode_utf8('  🐶 (en)'),
		decode_utf8('  🐕 (en)'),
	],
	'Print aliases test (all languages, lang is blank string).',
);

# Test.
$obj = Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Dog->new;
@ret = print_aliases($obj, { 'texts' => texts() },
	\&Wikibase::Datatype::Print::Value::Monolingual::print);
is_deeply(
	\@ret,
	[
		'Aliases:',
		decode_utf8('  pes domácí (cs)'),
		'  domestic dog (en)',
		'  Canis lupus familiaris (en)',
		'  Canis familiaris (en)',
		'  dogs (en)',
		decode_utf8('  🐶 (en)'),
		decode_utf8('  🐕 (en)'),
	],
	'Print aliases test (all languages, lang is undefined).',
);
