use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 27;
use Test::NoWarnings;
use Wikibase::Datatype::Struct::Property;

# Test.
my $struct_hr = {
	'datatype' => 'external-id',
	'ns' => 1200,
	'type' => 'property',
};
my $ret = Wikibase::Datatype::Struct::Property::struct2obj($struct_hr);
isa_ok($ret, 'Wikibase::Datatype::Property');
is($ret->datatype, 'external-id', 'Method datatype().');
is($ret->id, undef, 'Method id().');
is($ret->lastrevid, undef, 'Method lastrevid().');
is($ret->modified, undef, 'Method modified().');
is($ret->ns, 1200, 'Method ns().');
is($ret->page_id, undef, 'Method page_id().');
is($ret->title, undef, 'Method title().');

# Test.
$struct_hr = {
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
};
$ret = Wikibase::Datatype::Struct::Property::struct2obj($struct_hr);
isa_ok($ret, 'Wikibase::Datatype::Property');
is($ret->datatype, 'wikibase-item', 'Method datatype().');
is($ret->id, 'P31', 'Method id().');
is($ret->lastrevid, 1645333097, 'Method lastrevid().');
is($ret->modified, '2022-06-24T13:05:10Z', 'Method modified().');
is($ret->ns, 120, 'Method ns().');
is($ret->page_id, 3918489, 'Method page_id().');
is($ret->title, 'Property:P31', 'Method title().');

# Test.
$struct_hr = {};
eval {
	Wikibase::Datatype::Struct::Property::struct2obj($struct_hr);
};
is($EVAL_ERROR, "Structure isn't for 'property' type.\n",
	"Structure isn't for 'property' type.");
clean();

# Test.
$struct_hr = {
	'type' => 'bad',
};
eval {
	Wikibase::Datatype::Struct::Property::struct2obj($struct_hr);
};
is($EVAL_ERROR, "Structure isn't for 'property' type.\n",
	"Structure isn't for 'property' type.");
clean();

# Test.
$struct_hr = {
	'datatype' => 'external-id',
	'type' => 'property',
};
$ret = Wikibase::Datatype::Struct::Property::struct2obj($struct_hr);
isa_ok($ret, 'Wikibase::Datatype::Property');
is($ret->datatype, 'external-id', 'Method datatype().');
is($ret->id, undef, 'Method id().');
is($ret->lastrevid, undef, 'Method lastrevid().');
is($ret->modified, undef, 'Method modified().');
is($ret->ns, 120, 'Method ns() (120 - default).');
is($ret->page_id, undef, 'Method page_id().');
is($ret->title, undef, 'Method title().');
