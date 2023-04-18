use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 8;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Form::Wikidata::DogCzechSingular;
use Unicode::UTF8 qw(decode_utf8);
use Wikibase::Datatype::Item;
use Wikibase::Datatype::Print::Statement;
use Wikibase::Datatype::Print::Utils qw(print_common);
use Wikibase::Datatype::Print::Value::Monolingual;
use Wikibase::Datatype::Value::Monolingual;

# Test.
my $obj = Test::Shared::Fixture::Wikibase::Datatype::Form::Wikidata::DogCzechSingular->new;
my @ret = print_common($obj, {},
	'statements',
	\&Wikibase::Datatype::Print::Statement::print,
	'Statements');
is_deeply(
	\@ret,
	[
		'Statements:',
		decode_utf8('  P898: pɛs (normal)'),
	],
	'Print commons test (statements).',
);

# Test.
$obj = Wikibase::Datatype::Item->new(
	'aliases' => [
		Wikibase::Datatype::Value::Monolingual->new(
			'language' => 'en',
			'value' => 'dog',
		),
		Wikibase::Datatype::Value::Monolingual->new(
			'language' => 'cs',
			'value' => 'pes',
		),
	],
);
@ret = print_common($obj, {},
	'aliases',
	\&Wikibase::Datatype::Print::Value::Monolingual::print,
	'Aliases');
is_deeply(
	\@ret,
	[
		'Aliases:',
		'  dog (en)',
		'  pes (cs)',
	],
	'Print commons test (aliases - all).',
);

# Test.
$obj = Wikibase::Datatype::Item->new(
	'aliases' => [
		Wikibase::Datatype::Value::Monolingual->new(
			'language' => 'en',
			'value' => 'dog',
		),
		Wikibase::Datatype::Value::Monolingual->new(
			'language' => 'cs',
			'value' => 'pes',
		),
	],
);
@ret = print_common($obj, {},
	'aliases',
	\&Wikibase::Datatype::Print::Value::Monolingual::print,
	'Aliases', sub { grep { $_->language eq 'cs' } @_ });
is_deeply(
	\@ret,
	[
		'Aliases:',
		'  pes (cs)',
	],
	'Print commons test (aliases - cs).',
);

# Test.
$obj = Wikibase::Datatype::Item->new(
	'aliases' => [
		Wikibase::Datatype::Value::Monolingual->new(
			'language' => 'en',
			'value' => 'dog',
		),
		Wikibase::Datatype::Value::Monolingual->new(
			'language' => 'cs',
			'value' => 'pes',
		),
	],
);
@ret = print_common($obj, {},
	'aliases',
	\&Wikibase::Datatype::Print::Value::Monolingual::print,
	'Aliases', sub { grep { $_->language eq 'en' } @_ });
is_deeply(
	\@ret,
	[
		'Aliases:',
		'  dog (en)',
	],
	'Print commons test (aliases - en).',
);

# Test.
$obj = Wikibase::Datatype::Item->new(
	'labels' => [
		Wikibase::Datatype::Value::Monolingual->new(
			'language' => 'en',
			'value' => 'label',
		),
	],
);
@ret = print_common($obj, {},
	'labels',
	\&Wikibase::Datatype::Print::Value::Monolingual::print,
	'Label', sub { grep { $_->language eq 'en' } @_ }, 1);
is_deeply(
	\@ret,
	[
		'Label: label (en)',
	],
	'Print commons test (labels - one line).',
);

# Test.
$obj = Wikibase::Datatype::Item->new(
	'labels' => [
		Wikibase::Datatype::Value::Monolingual->new(
			'language' => 'en',
			'value' => 'label',
		),
	],
);
@ret = print_common($obj, {},
	'labels',
	\&Wikibase::Datatype::Print::Value::Monolingual::print,
	'Label', sub { grep { $_->language eq 'en' } @_ }, 0);
is_deeply(
	\@ret,
	[
		'Label:',
		'  label (en)',
	],
	'Print commons test (labels - multiple lines).',
);

# Test.
$obj = Wikibase::Datatype::Item->new(
	'aliases' => [
		Wikibase::Datatype::Value::Monolingual->new(
			'language' => 'en',
			'value' => 'dog',
		),
		Wikibase::Datatype::Value::Monolingual->new(
			'language' => 'cs',
			'value' => 'pes',
		),
	],
);
eval {
	print_common($obj, {}, 'aliases',
	\&Wikibase::Datatype::Print::Value::Monolingual::print,
	'Aliases', undef, 1);
};
is($EVAL_ERROR, "Multiple values are printed to one line.\n",
	"Multiple values are printed to one line.");
clean();
