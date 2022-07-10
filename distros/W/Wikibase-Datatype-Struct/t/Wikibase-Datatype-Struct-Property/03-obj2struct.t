use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 7;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Property::Wikidata::InstanceOf;
use Wikibase::Datatype::Property;
use Wikibase::Datatype::Struct::Property;

# Test.
my $obj = Wikibase::Datatype::Property->new(
	'datatype' => 'external-id',
);
my $ret_hr = Wikibase::Datatype::Struct::Property::obj2struct($obj,
	'http://test.wikidata.org/entity/');
is_deeply(
	$ret_hr,
	{
		'datatype' => 'external-id',
		'ns' => 120,
		'type' => 'property',
	},
	'Output of obj2struct() subroutine. Empty structure (external-id).',
);

# Test.
$obj = Test::Shared::Fixture::Wikibase::Datatype::Property::Wikidata::InstanceOf->new;
$ret_hr = Wikibase::Datatype::Struct::Property::obj2struct($obj,
	'http://test.wikidata.org/entity/');
is_deeply(
	$ret_hr,
	{
		'aliases' => {
			'en' => [{
				'language' => 'en',
				'value' => 'is a',
			}, {
				'language' => 'en',
				'value' => 'is an',
			}],
		},
		'claims' => {
			'P31' => [{
				'mainsnak' => {
					'datatype' => 'wikibase-item',
					'datavalue' => {
						'type' => 'wikibase-entityid',
						'value' => {
							'entity-type' => 'item',
							'id' => 'Q32753077',
							'numeric-id' => 32753077,
						},
					},
					'property' => 'P31',
					'snaktype' => 'value',
				},
				'rank' => 'normal',
				'type' => 'statement',
			}],
		},
		'datatype' => 'wikibase-item',
		'descriptions' => {
			'en' => {
				'language' => 'en',
				'value' => 'that class of which this subject is a particular example and member',
			},
		},
		'id' => 'P31',
		'labels' => {
			'en' => {
				'language' => 'en',
				'value' => 'instance of',
			},
		},
		'lastrevid' => 1645333097,
		'modified' => '2022-06-24T13:05:10Z',
		'ns' => 120,
		'pageid' => 3918489,
		'title' => 'Property:P31',
		'type' => 'property',
	},
	'Output of obj2struct() subroutine. Complex structure.',
);

# Test.
eval {
	Wikibase::Datatype::Struct::Property::obj2struct('bad');
};
is($EVAL_ERROR, "Object isn't 'Wikibase::Datatype::Property'.\n",
	"Object isn't 'Wikibase::Datatype::Property'.");
clean();

# Test.
eval {
	Wikibase::Datatype::Struct::Property::obj2struct();
};
is($EVAL_ERROR, "Object doesn't exist.\n", "Object doesn't exist.");
clean();

# Test.
$obj = Wikibase::Datatype::Property->new(
	'datatype' => 'external-id',
);
eval {
	Wikibase::Datatype::Struct::Property::obj2struct($obj);
};
is($EVAL_ERROR, "Base URI is required.\n", 'Base URI is required.');
clean();

# Test.
$obj = Wikibase::Datatype::Property->new(
	'datatype' => 'external-id',
	'ns' => undef,
);
$ret_hr = Wikibase::Datatype::Struct::Property::obj2struct($obj,
	'http://test.wikidata.org/entity/');
is_deeply(
	$ret_hr,
	{
		'datatype' => 'external-id',
		'type' => 'property',
	},
	'Output of obj2struct() subroutine. Undefined name space.',
);
