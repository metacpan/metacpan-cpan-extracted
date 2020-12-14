use strict;
use warnings;

use Test::More 'tests' => 5;
use Test::NoWarnings;
use Wikibase::Datatype::Struct::Sense;

# Test.
my $struct_hr = {
	'glosses' => {
		'cs' => {
			'language' => 'cs',
			'value' => 'Glosse cs',
		},
		'en' => {
			'language' => 'en',
			'value' => 'Glosse en',
		},
	},
	'id' => 'ID',
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
};
my $ret = Wikibase::Datatype::Struct::Sense::struct2obj($struct_hr);
isa_ok($ret, 'Wikibase::Datatype::Sense');
is($ret->id, 'ID', 'Method id().');
is((scalar @{$ret->glosses}), 2, 'Method glosses.');
is((scalar @{$ret->statements}), 1, 'Method statements.');
