use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 8;
use Test::NoWarnings;
use Wikibase::Datatype::Mediainfo;
use Wikibase::Datatype::MediainfoSnak;
use Wikibase::Datatype::MediainfoStatement;
use Wikibase::Datatype::Struct::Mediainfo;
use Wikibase::Datatype::Value::Item;
use Wikibase::Datatype::Value::Monolingual;

# Test.
my $obj = Wikibase::Datatype::Mediainfo->new;
my $ret_hr = Wikibase::Datatype::Struct::Mediainfo::obj2struct($obj,
	'http://test.wikidata.org/entity/');
is_deeply(
	$ret_hr,
	{
		'descriptions' => {},
		'ns' => 6,
		'type' => 'mediainfo',
	},
	'Output of obj2struct() subroutine. Empty structure.',
);

# Test.
my $statement1 = Wikibase::Datatype::MediainfoStatement->new(
	# instance of (P31) human (Q5)
	'snak' => Wikibase::Datatype::MediainfoSnak->new(
		'datavalue' => Wikibase::Datatype::Value::Item->new(
			'value' => 'Q5',
		),
		'property' => 'P31',
	),
	'property_snaks' => [
		# of (P642) alien (Q474741)
		Wikibase::Datatype::MediainfoSnak->new(
			'datavalue' => Wikibase::Datatype::Value::Item->new(
				'value' => 'Q474741',
			),
			'property' => 'P642',
		),
	],
);
my $statement2 = Wikibase::Datatype::MediainfoStatement->new(
	# sex or gender (P21) male (Q6581097)
	'snak' => Wikibase::Datatype::MediainfoSnak->new(
		'datavalue' => Wikibase::Datatype::Value::Item->new(
			'value' => 'Q6581097',
		),
		'property' => 'P21',
	),
);
$obj = Wikibase::Datatype::Mediainfo->new(
	'id' => 'Q42',
	'labels' => [
		Wikibase::Datatype::Value::Monolingual->new(
			'language' => 'cs',
			'value' => 'Douglas Adams',
		),
		Wikibase::Datatype::Value::Monolingual->new(
			'language' => 'en',
			'value' => 'Douglas Adams',
		),
	],
	'lastrevid' => 534820,
	'modified' => '2020-12-02T13:39:18Z',
	'page_id' => 123,
	'statements' => [
		$statement1,
		$statement2,
	],
	'title' => 'Q42',
);
$ret_hr = Wikibase::Datatype::Struct::Mediainfo::obj2struct($obj,
	'http://test.wikidata.org/entity/');
is_deeply(
	$ret_hr,
	{
		'descriptions' => {},
		'id' => 'Q42',
		'labels' => {
			'cs' => {
				'language' => 'cs',
				'value' => 'Douglas Adams',
			},
			'en' => {
				'language' => 'en',
				'value' => 'Douglas Adams',
			},
		},
		'lastrevid' => 534820,
		'modified' => '2020-12-02T13:39:18Z',
		'ns' => 6,
		'pageid' => 123,
		'statements' => {
			'P21' => [{
				'mainsnak' => {
					'datavalue' => {
						'value' => {
							'entity-type' => 'item',
							'id' => 'Q6581097',
							'numeric-id' => 6581097,
						},
						'type' => 'wikibase-entityid',
					},
					'property' => 'P21',
					'snaktype' => 'value',
				},
				'rank' => 'normal',
				'type' => 'statement',
			}],
			'P31' => [{
				'mainsnak' => {
					'datavalue' => {
						'value' => {
							'entity-type' => 'item',
							'id' => 'Q5',
							'numeric-id' => 5,
						},
						'type' => 'wikibase-entityid',
					},
					'property' => 'P31',
					'snaktype' => 'value',
				},
				'qualifiers' => {
					'P642' => [{
						'datavalue' => {
							'value' => {
								'entity-type' => 'item',
								'id' => 'Q474741',
								'numeric-id' => 474741,
							},
							'type' => 'wikibase-entityid',
						},
						'property' => 'P642',
						'snaktype' => 'value',
					}],
				},
				'qualifiers-order' => [
					'P642',
				],
				'rank' => 'normal',
				'type' => 'statement',
			}],
		},
		'title' => 'Q42',
		'type' => 'mediainfo',
	},
	'Output of obj2struct() subroutine. Complex structure.',
);

# Test.
eval {
	Wikibase::Datatype::Struct::Mediainfo::obj2struct('bad');
};
is($EVAL_ERROR, "Object isn't 'Wikibase::Datatype::Mediainfo'.\n",
	"Object isn't 'Wikibase::Datatype::Mediainfo'.");
clean();

# Test.
eval {
	Wikibase::Datatype::Struct::Mediainfo::obj2struct();
};
is($EVAL_ERROR, "Object doesn't exist.\n", "Object doesn't exist.");
clean();

# Test.
$obj = Wikibase::Datatype::Mediainfo->new;
eval {
	Wikibase::Datatype::Struct::Mediainfo::obj2struct($obj);
};
is($EVAL_ERROR, "Base URI is required.\n", 'Base URI is required.');
clean();

# Test.
$obj = Wikibase::Datatype::Mediainfo->new(
	'statements' => [
		Wikibase::Datatype::MediainfoStatement->new(
			'snak' => Wikibase::Datatype::MediainfoSnak->new(
				'datavalue' => Wikibase::Datatype::Value::String->new(
					'value' => '1.1',
				),
				'property' => 'P11',
			),
			'rank' => 'normal',
		),
		Wikibase::Datatype::MediainfoStatement->new(
			'snak' => Wikibase::Datatype::MediainfoSnak->new(
				'property' => 'P11',
				'snaktype' => 'novalue',
			),
			'rank' => 'normal',
		),
	],
);
$ret_hr = Wikibase::Datatype::Struct::Mediainfo::obj2struct($obj,
	'http://test.wikidata.org/entity/');
is_deeply(
	$ret_hr,
	{
		'descriptions' => {},
		'ns' => 6,
		'statements' => {
			'P11' => [{
				'mainsnak' => {
					'datavalue' => {
						'value' => '1.1',
						'type' => 'string',
					},
					'property' => 'P11',
					'snaktype' => 'value',
				},
				'rank' => 'normal',
				'type' => 'statement',
			}, {
				'mainsnak' => {
					'property' => 'P11',
					'snaktype' => 'novalue',
				},
				'rank' => 'normal',
				'type' => 'statement',
			}],
		},
		'type' => 'mediainfo',
	},
	'Output of obj2struct() subroutine. Two claims for one property.',
);

# Test.
$obj = Wikibase::Datatype::Mediainfo->new(
	'ns' => undef,
);
$ret_hr = Wikibase::Datatype::Struct::Mediainfo::obj2struct($obj,
	'http://test.wikidata.org/entity/');
is_deeply(
	$ret_hr,
	{
		'descriptions' => {},
		'type' => 'mediainfo',
	},
	'Output of obj2struct() subroutine. Undefined name space.',
);
