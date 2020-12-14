use strict;
use warnings;

use Test::More 'tests' => 15;
use Test::NoWarnings;
use Wikibase::Datatype::Struct::Item;

# Test.
my $struct_hr = {
	'ns' => 0,
	'type' => 'item',
};
my $ret = Wikibase::Datatype::Struct::Item::struct2obj($struct_hr);
isa_ok($ret, 'Wikibase::Datatype::Item');
is($ret->id, undef, 'Method id().');
is($ret->lastrevid, undef, 'Method lastrevid().');
is($ret->modified, undef, 'Method modified().');
is($ret->ns, 0, 'Method ns().');
is($ret->page_id, undef, 'Method page_id().');
is($ret->title, undef, 'Method title().');

# Test.
$struct_hr = {
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
};
$ret = Wikibase::Datatype::Struct::Item::struct2obj($struct_hr);
isa_ok($ret, 'Wikibase::Datatype::Item');
is($ret->id, 'Q42', 'Method id().');
is($ret->lastrevid, '534820', 'Method lastrevid().');
is($ret->modified, '2020-12-02T13:39:18Z', 'Method modified().');
is($ret->ns, 0, 'Method ns().');
is($ret->page_id, 123, 'Method page_id().');
is($ret->title, 'Q42', 'Method title().');
