use strict;
use warnings;

use Test::More 'tests' => 6;
use Test::NoWarnings;
use Wikibase::Datatype::Struct::Form;

# Test.
my $struct_hr = {
	'claims' => {
		'P31' => [{
			'mainsnak' => {
				'datatype' => 'wikibase-item',
				'datavalue' => {
					'type' => 'wikibase-entityid',
					'value' => {
						'entity-type' => 'item',
						'id' => 'Q5',
						'numeric-id' => 5,
					},
				},
				'property' => 'P31',
				'snaktype' => 'value',
			},
			'rank' => 'normal',
			'type' => 'statement',
		}],
	},
	'grammaticalFeatures' => [
		'Q163012',
		'Q163014',
	],
	'id' => 'ID',
	'representations' => {
		'cs' => {
			'language' => 'cs',
			'value' => 'Glosse cs',
		},
		'en' => {
			'language' => 'en',
			'value' => 'Glosse en',
		},
	},
};
my $ret = Wikibase::Datatype::Struct::Form::struct2obj($struct_hr);
isa_ok($ret, 'Wikibase::Datatype::Form');
is($ret->id, 'ID', 'Method id().');
is((scalar @{$ret->grammatical_features}), 2, 'Method grammatical features.');
is((scalar @{$ret->representations}), 2, 'Method representations.');
is((scalar @{$ret->statements}), 1, 'Method statements.');
