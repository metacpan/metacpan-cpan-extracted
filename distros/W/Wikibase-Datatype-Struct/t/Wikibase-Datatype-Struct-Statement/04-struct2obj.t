use strict;
use warnings;

use Test::More 'tests' => 10;
use Test::NoWarnings;
use Wikibase::Datatype::Struct::Statement;

# Test.
my $struct_hr = {
	'id' => 'Q123$00C04D2A-49AF-40C2-9930-C551916887E8',
	'mainsnak' => {
		'datatype' => 'string',
		'datavalue' => {
			'type' => 'string',
			'value' => '1.1',
		},
		'property' => 'P11',
		'snaktype' => 'value',
	},
	'qualifiers-order' => [
		'P642',
	],
	'qualifiers' => {
		'P642' => [
			{
				'datatype' => 'wikibase-item',
				'datavalue' => {
					'type' => 'wikibase-entityid',
					'value' => {
						'id' => 'Q474741',
						'entity-type' => 'item',
					},
				},
				'property' => 'P642',
				'snaktype' => 'value',
			},
		],
	},
	'rank' => 'normal',
	'references' => [
		{
			'snaks' => {
				'P248' => [{
					'datatype' => 'wikibase-item',
					'datavalue' => {
						'value' => {
							'id' => 'Q53919',
							'entity-type' => 'item',
						},
						'type' => 'wikibase-entityid'
					},
					'property' => 'P248',
					'snaktype' => 'value',
				}],
				'P214' => [{
					'datatype' => 'external-id',
					'datavalue' => {
						'value' => '113230702',
						'type' => 'string',
					},
					'property' => 'P214',
					'snaktype' => 'value',
				}],
				'P813' => [{
					'datatype' => 'time',
					'datavalue' => {
						'value' => {
							'after' => 0,
							'before' => 0,
							'calendarmodel' => 'http://www.wikidata.org/entity/Q1985727',
							'precision' => 11,
							'time' => '+2013-12-07T00:00:00Z',
							'timezone' => 0,
						},
						'type' => 'time',
					},
					'property' => 'P813',
					'snaktype' => 'value',
				}],
			},
			'snaks-order' => [
				'P248',
				'P214',
				'P813'
			],
		},
	],
	'type' => 'statement',
};
my $ret = Wikibase::Datatype::Struct::Statement::struct2obj($struct_hr);
isa_ok($ret, 'Wikibase::Datatype::Statement');
isa_ok($ret->snak, 'Wikibase::Datatype::Snak');
is($ret->id, 'Q123$00C04D2A-49AF-40C2-9930-C551916887E8', 'Method id().');
is($ret->rank, 'normal', 'Method rank().');
is(@{$ret->references}, 1, 'Count of references.');
is(@{$ret->references->[0]->snaks}, 3, 'Count of snaks in reference.');
is(@{$ret->property_snaks}, 1, 'Count of property snaks.');
is($ret->property_snaks->[0]->property, 'P642', 'Qualifier property.');
is($ret->property_snaks->[0]->datavalue->value, 'Q474741', 'Qualifier datavalue.');
