use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 6;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);
use Wikibase::Datatype::Reference;
use Wikibase::Datatype::Snak;
use Wikibase::Datatype::Value::String;
use Wikibase::Datatype::Struct::Reference;

# Test.
my $obj = Wikibase::Datatype::Reference->new(
	'snaks' => [
		Wikibase::Datatype::Snak->new(
			'datatype' => 'url',
			'datavalue' => Wikibase::Datatype::Value::String->new(
				'value' => 'https://skim.cz',
			),
			'property' => 'P93',
		),
	],
);
my $ret_hr = Wikibase::Datatype::Struct::Reference::obj2struct($obj,
	'https://test.wikidata.org/entity');
is_deeply(
	$ret_hr,
	{
		'snaks' => {
			'P93' => [
				{
					'datatype' => 'url',
					'datavalue' => {
						'value' => 'https://skim.cz',
						'type' => 'string',
					},
					'snaktype' => 'value',
					'property' => 'P93',
				},
			],
		},
		'snaks-order' => [
			'P93',
		],
	},
	'Output of obj2struct() subroutine.',
);

# Test.
$obj = Wikibase::Datatype::Reference->new(
	'snaks' => [
		Wikibase::Datatype::Snak->new(
			'datatype' => 'url',
			'datavalue' => Wikibase::Datatype::Value::String->new(
				'value' => 'https://skim.cz',
			),
			'property' => 'P93',
		),
		Wikibase::Datatype::Snak->new(
			'datatype' => 'url',
			'datavalue' => Wikibase::Datatype::Value::String->new(
				'value' => 'https://example.com',
			),
			'property' => 'P93',
		),
		Wikibase::Datatype::Snak->new(
			'datatype' => 'string',
			'datavalue' => Wikibase::Datatype::Value::String->new(
				'value' => 'foo',
			),
			'property' => 'P31',
		),
	],
);
$ret_hr = Wikibase::Datatype::Struct::Reference::obj2struct($obj,
	'https://test.wikidata.org/entity');
is_deeply(
	$ret_hr,
	{
		'snaks' => {
			'P93' => [
				{
					'datatype' => 'url',
					'datavalue' => {
						'value' => 'https://skim.cz',
						'type' => 'string',
					},
					'snaktype' => 'value',
					'property' => 'P93',
				}, {
					'datatype' => 'url',
					'datavalue' => {
						'value' => 'https://example.com',
						'type' => 'string',
					},
					'snaktype' => 'value',
					'property' => 'P93',
				},
			],
			'P31' => [
				{
					'datatype' => 'string',
					'datavalue' => {
						'value' => 'foo',
						'type' => 'string',
					},
					'snaktype' => 'value',
					'property' => 'P31',
				},
			],
		},
		'snaks-order' => [
			'P93',
			'P31',
		],
	},
	'Output of obj2struct() subroutine. Multiple values.',
);

# Test.
eval {
	Wikibase::Datatype::Struct::Reference::obj2struct('bad');
};
is($EVAL_ERROR, "Object isn't 'Wikibase::Datatype::Reference'.\n",
	"Object isn't 'Wikibase::Datatype::Reference'.");
clean();

# Test.
$obj = Wikibase::Datatype::Reference->new(
	'snaks' => [
		Wikibase::Datatype::Snak->new(
			'datatype' => 'url',
			'datavalue' => Wikibase::Datatype::Value::String->new(
				'value' => 'https://skim.cz',
			),
			'property' => 'P93',
		),
	],
);
eval {
	Wikibase::Datatype::Struct::Reference::obj2struct($obj);
};
is($EVAL_ERROR, "Base URI is required.\n", 'Base URI is required.');
clean();

# Test.
eval {
	Wikibase::Datatype::Struct::Reference::obj2struct();
};
is($EVAL_ERROR, "Object doesn't exist.\n", "Object doesn't exist.");
clean();
