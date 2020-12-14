use strict;
use warnings;

use Test::More 'tests' => 15;
use Test::NoWarnings;
use Wikibase::Datatype::Struct::Reference;

# Test.
my $struct_hr = {
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
};
my $ret = Wikibase::Datatype::Struct::Reference::struct2obj($struct_hr);
isa_ok($ret, 'Wikibase::Datatype::Reference');
is($ret->snaks->[0]->property, 'P93', 'Get property.');
is($ret->snaks->[0]->datatype, 'url', 'Get datatype.');
is($ret->snaks->[0]->datavalue->value, 'https://skim.cz', 'Get value.');

# Test.
$struct_hr = {
	'snaks' => {
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
	},
	'snaks-order' => [
		'P93',
		'P31',
	],
};
$ret = Wikibase::Datatype::Struct::Reference::struct2obj($struct_hr);
isa_ok($ret, 'Wikibase::Datatype::Reference');
is($ret->snaks->[0]->property, 'P93', 'Get #1 item property.');
is($ret->snaks->[0]->datatype, 'url', 'Get #1 item datatype.');
is($ret->snaks->[0]->datavalue->value, 'https://skim.cz', 'Get #1 item value.');
is($ret->snaks->[1]->property, 'P93', 'Get #2 item property.');
is($ret->snaks->[1]->datatype, 'url', 'Get #2 item datatype.');
is($ret->snaks->[1]->datavalue->value, 'https://example.com', 'Get #2 item value.');
is($ret->snaks->[2]->property, 'P31', 'Get #3 item property.');
is($ret->snaks->[2]->datatype, 'string', 'Get #3 item datatype.');
is($ret->snaks->[2]->datavalue->value, 'foo', 'Get #3 item value.');
