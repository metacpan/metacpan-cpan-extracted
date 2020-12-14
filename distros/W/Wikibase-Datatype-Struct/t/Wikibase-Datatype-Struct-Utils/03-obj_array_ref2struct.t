use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 4;
use Test::NoWarnings;
use Wikibase::Datatype::Snak;
use Wikibase::Datatype::Struct::Utils qw(obj_array_ref2struct);
use Wikibase::Datatype::Value::String;

# Test.
my $snaks_ar = [
	Wikibase::Datatype::Snak->new(
		'datatype' => 'string',
		'datavalue' => Wikibase::Datatype::Value::String->new(
			'value' => 'text',
		),
		'property' => 'P1',
	),
	Wikibase::Datatype::Snak->new(
		'datatype' => 'string',
		'datavalue' => Wikibase::Datatype::Value::String->new(
			'value' => 'foo',
		),
		'property' => 'P2',
	),
];
my $ret_hr = obj_array_ref2struct($snaks_ar, 'foo',
	'https://test.wikidata.org/entity');
is_deeply(
	$ret_hr,
	{
		'foo' => {
			'P1' => [{
				'datatype' => 'string',
				'datavalue' => {
					'type' => 'string',
					'value' => 'text',
				},
				'property' => 'P1',
				'snaktype' => 'value',
			}],
			'P2' => [{
				'datatype' => 'string',
				'datavalue' => {
					'type' => 'string',
					'value' => 'foo',
				},
				'property' => 'P2',
				'snaktype' => 'value',
			}],
		},
		'foo-order' => [
			'P1',
			'P2',
		],
	},
	'Convert two snaks in array to structure.',
);

# Test.
$snaks_ar = ['bad'];
eval {
	obj_array_ref2struct($snaks_ar, 'foo',
		'https://test.wikidata.org/entity');
};
is($EVAL_ERROR, "Object isn't 'Wikibase::Datatype::Snak'.\n",
	"Object isn't 'Wikibase::Datatype::Snak");
clean();

# Test.
$snaks_ar = [
	Wikibase::Datatype::Snak->new(
		'datatype' => 'string',
		'datavalue' => Wikibase::Datatype::Value::String->new(
			'value' => 'text',
		),
		'property' => 'P1',
	),
	Wikibase::Datatype::Snak->new(
		'datatype' => 'string',
		'datavalue' => Wikibase::Datatype::Value::String->new(
			'value' => 'foo',
		),
		'property' => 'P2',
	),
];
eval {
	obj_array_ref2struct($snaks_ar, 'foo');
};
is($EVAL_ERROR, "Base URI is required.\n", 'Base URI is required.');
clean();
