use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 5;
use Test::NoWarnings;
use Wikibase::Datatype::Item;
use Wikibase::Datatype::Snak;
use Wikibase::Datatype::Statement;
use Wikibase::Datatype::Struct::Item;
use Wikibase::Datatype::Value::Item;
use Wikibase::Datatype::Value::Monolingual;

# Test.
my $obj = Wikibase::Datatype::Item->new;
my $ret_hr = Wikibase::Datatype::Struct::Item::obj2struct($obj,
	'http://test.wikidata.org/entity/');
is_deeply(
	$ret_hr,
	{
		'ns' => 0,
		'type' => 'item',
	},
	'Output of obj2struct() subroutine. Empty structure.',
);

# Test.
my $statement1 = Wikibase::Datatype::Statement->new(
	# instance of (P31) human (Q5)
	'snak' => Wikibase::Datatype::Snak->new(
		'datatype' => 'wikibase-item',
		'datavalue' => Wikibase::Datatype::Value::Item->new(
			'value' => 'Q5',
		),
		'property' => 'P31',
	),
	'property_snaks' => [
		# of (P642) alien (Q474741)
		Wikibase::Datatype::Snak->new(
			'datatype' => 'wikibase-item',
			'datavalue' => Wikibase::Datatype::Value::Item->new(
				'value' => 'Q474741',
			),
			'property' => 'P642',
		),
	],
	'references' => [
		 Wikibase::Datatype::Reference->new(
			'snaks' => [
				# stated in (P248) Virtual International Authority File (Q53919)
				Wikibase::Datatype::Snak->new(
					'datatype' => 'wikibase-item',
					'datavalue' => Wikibase::Datatype::Value::Item->new(
						'value' => 'Q53919',
					),
					'property' => 'P248',
				),

				# VIAF ID (P214) 113230702
				Wikibase::Datatype::Snak->new(
					'datatype' => 'external-id',
					'datavalue' => Wikibase::Datatype::Value::String->new(
						'value' => '113230702',
					),
					'property' => 'P214',
				),

				# retrieved (P813) 7 December 2013
				Wikibase::Datatype::Snak->new(
					'datatype' => 'time',
					'datavalue' => Wikibase::Datatype::Value::Time->new(
						'value' => '+2013-12-07T00:00:00Z',
					),
					'property' => 'P813',
				),
			],
		),
	],
);
my $statement2 = Wikibase::Datatype::Statement->new(
	# sex or gender (P21) male (Q6581097)
	'snak' => Wikibase::Datatype::Snak->new(
		'datatype' => 'wikibase-item',
		'datavalue' => Wikibase::Datatype::Value::Item->new(
			'value' => 'Q6581097',
		),
		'property' => 'P21',
	),
	'references' => [
		Wikibase::Datatype::Reference->new(
			'snaks' => [
				# stated in (P248) Virtual International Authority File (Q53919)
				Wikibase::Datatype::Snak->new(
					'datatype' => 'wikibase-item',
					'datavalue' => Wikibase::Datatype::Value::Item->new(
						'value' => 'Q53919',
					),
					'property' => 'P248',
				),

				# VIAF ID (P214) 113230702
				Wikibase::Datatype::Snak->new(
					'datatype' => 'external-id',
					'datavalue' => Wikibase::Datatype::Value::String->new(
						'value' => '113230702',
					),
					'property' => 'P214',
				),

				# retrieved (P813) 7 December 2013
				Wikibase::Datatype::Snak->new(
					'datatype' => 'time',
					'datavalue' => Wikibase::Datatype::Value::Time->new(
						'value' => '+2013-12-07T00:00:00Z',
					),
					'property' => 'P813',
				),
			],
		),
	],
);
$obj = Wikibase::Datatype::Item->new(
	'aliases' => [
		Wikibase::Datatype::Value::Monolingual->new(
			'language' => 'cs',
			'value' => 'Douglas Noël Adams',
		),
		Wikibase::Datatype::Value::Monolingual->new(
			'language' => 'cs',
			'value' => 'Douglas Noel Adams',
		),
		Wikibase::Datatype::Value::Monolingual->new(
			'language' => 'en',
			'value' => 'Douglas Noël Adams',
		),
		Wikibase::Datatype::Value::Monolingual->new(
			'language' => 'en',
			'value' => 'Douglas Noel Adams',
		),
	],
	'descriptions' => [
		Wikibase::Datatype::Value::Monolingual->new(
			'language' => 'cs',
			'value' => 'anglický spisovatel, humorista a dramatik',
		),
		Wikibase::Datatype::Value::Monolingual->new(
			'language' => 'en',
			'value' => 'English writer and humorist',
		),
	],
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
	'sitelinks' => [
		Wikibase::Datatype::Sitelink->new(
			'site' => 'cswiki',
			'title' => 'Douglas Adams',
		),
		Wikibase::Datatype::Sitelink->new(
			'site' => 'enwiki',
			'title' => 'Douglas Adams',
		),
	],
	'statements' => [
		$statement1,
		$statement2,
	],
	'title' => 'Q42',
);
$ret_hr = Wikibase::Datatype::Struct::Item::obj2struct($obj,
	'http://test.wikidata.org/entity/');
is_deeply(
	$ret_hr,
	{
		'aliases' => {
			'en' => [{
				'language' => 'en',
				'value' => 'Douglas Noël Adams',
			}, {
				'language' => 'en',
				'value' => 'Douglas Noel Adams',
			}],
			'cs' => [{
				'language' => 'cs',
				'value' => 'Douglas Noël Adams',
			}, {
				'language' => 'cs',
				'value' => 'Douglas Noel Adams',
			}],
		},
		'claims' => {
			'P21' => [{
				'mainsnak' => {
					'datatype' => 'wikibase-item',
					'datavalue' => {
						'type' => 'wikibase-entityid',
						'value' => {
							'entity-type' => 'item',
							'id' => 'Q6581097',
							'numeric-id' => 6581097,
						},
					},
					'property' => 'P21',
					'snaktype' => 'value',
				},
				'rank' => 'normal',
				'references' => [{
					'snaks' => {
						'P214' => [{
							'datatype' => 'external-id',
							'datavalue' => {
								'type' => 'string',
								'value' => '113230702',
							},
							'property' => 'P214',
							'snaktype' => 'value',
						}],
						'P248' => [{
							'datatype' => 'wikibase-item',
							'datavalue' => {
								'type' => 'wikibase-entityid',
								'value' => {
									'entity-type' => 'item',
									'id' => 'Q53919',
									'numeric-id' => '53919',
								},
							},
							'property' => 'P248',
							'snaktype' => 'value',
						}],
						'P813' => [{
							'datatype' => 'time',
							'datavalue' => {
								'type' => 'time',
								'value' => {
									'after' => 0,
									'before' => 0,
									'calendarmodel' => 'http://test.wikidata.org/entity/Q1985727',
									'precision' => 11,
									'time' => '+2013-12-07T00:00:00Z',
									'timezone' => 0,
								},
							},
							'property' => 'P813',
							'snaktype' => 'value',
						}],
					},
					'snaks-order' => [
						'P248',
						'P214',
						'P813',
					],
				}],
				'type' => 'statement',
			}],
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
				'qualifiers' => {
					'P642' => [{
						'datatype' => 'wikibase-item',
						'datavalue' => {
							'type' => 'wikibase-entityid',
							'value' => {
								'entity-type' => 'item',
								'id' => 'Q474741',
								'numeric-id' => 474741,
							},
						},
						'property' => 'P642',
						'snaktype' => 'value',
					}],
				},
				'qualifiers-order' => [
					'P642',
				],
				'rank' => 'normal',
				'references' => [{
					'snaks' => {
						'P214' => [{
							'datatype' => 'external-id',
							'datavalue' => {
								'type' => 'string',
								'value' => '113230702',
							},
							'property' => 'P214',
							'snaktype' => 'value',
						}],
						'P248' => [{
							'datatype' => 'wikibase-item',
							'datavalue' => {
								'type' => 'wikibase-entityid',
								'value' => {
									'entity-type' => 'item',
									'id' => 'Q53919',
									'numeric-id' => 53919,
								},
							},
							'property' => 'P248',
							'snaktype' => 'value',
						}],
						'P813' => [{
							'datatype' => 'time',
							'datavalue' => {
								'type' => 'time',
								'value' => {
									'after' => 0,
									'before' => 0,
									'calendarmodel' => 'http://test.wikidata.org/entity/Q1985727',
									'precision' => 11,
									'time' => '+2013-12-07T00:00:00Z',
									'timezone' => 0,
								},
							},
							'property' => 'P813',
							'snaktype' => 'value',
						}],
					},
					'snaks-order' => [
						'P248',
						'P214',
						'P813',
					],
				}],
				'type' => 'statement',
			}],
		},
		'descriptions' => {
			'en' => {
				'language' => 'en',
				'value' => 'English writer and humorist',
			},
			'cs' => {
				'language' => 'cs',
				'value' => 'anglický spisovatel, humorista a dramatik',
			},
		},
		'id' => 'Q42',
		'labels' => {
			'en' => {
				'language' => 'en',
				'value' => 'Douglas Adams',
			},
			'cs' => {
				'language' => 'cs',
				'value' => 'Douglas Adams',
			},
		},
		'lastrevid' => 534820,
		'modified' => '2020-12-02T13:39:18Z',
		'ns' => 0,
		'pageid' => 123,
		'sitelinks' => {
			'cswiki' => {
				'title' => 'Douglas Adams',
				'badges' => [],
				'site' => 'cswiki',
			},
			'enwiki' => {
				'title' => 'Douglas Adams',
				'badges' => [],
				'site' => 'enwiki',
			},
		},
		'title' => 'Q42',
		'type' => 'item',
	},
	'Output of obj2struct() subroutine. Complex structure.',
);

# Test.
eval {
	Wikibase::Datatype::Struct::Item::obj2struct('bad');
};
is($EVAL_ERROR, "Object isn't 'Wikibase::Datatype::Item'.\n",
	"Object isn't 'Wikibase::Datatype::Item'.");
clean();

# Test.
eval {
	Wikibase::Datatype::Struct::Item::obj2struct();
};
is($EVAL_ERROR, "Object doesn't exist.\n", "Object doesn't exist.");
clean();
