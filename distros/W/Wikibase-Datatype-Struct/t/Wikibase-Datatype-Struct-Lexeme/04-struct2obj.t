use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 20;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);
use Wikibase::Datatype::Struct::Lexeme;

# Test.
my $struct_hr = {
	'type' => 'lexeme',
};
my $ret = Wikibase::Datatype::Struct::Lexeme::struct2obj($struct_hr);
isa_ok($ret, 'Wikibase::Datatype::Lexeme');
is($ret->lastrevid, undef, 'Method lastrevid().');
is($ret->modified, undef, 'Method modified().');
is($ret->ns, 146, 'Method ns().');
is($ret->title, undef, 'Method title().');

# Test.
$struct_hr = {
	'claims' => {
		'P5185' => [{
			'mainsnak' => {
				'datavalue' => {
					'type' => 'wikibase-entityid',
					'value' => {
						'entity-type' => 'item',
						'id' => 'Q499327',
						'numeric-id' => 499327,
					},
				},
				'datatype' => 'wikibase-item',
				'property' => 'P5185',
				'snaktype' => 'value',
			},
			'rank' => 'normal',
			'references' => [{
				'snaks' => {
					'P214' => [{
						'datavalue' => {
							'type' => 'string',
							'value' => '113230702',
						},
						'datatype' => 'external-id',
						'property' => 'P214',
						'snaktype' => 'value',
					}],
					'P248' => [{
						'datavalue' => {
							'type' => 'wikibase-entityid',
							'value' => {
								'entity-type' => 'item',
								'id' => 'Q53919',
								'numeric-id' => 53919,
							},
						},
						'datatype' => 'wikibase-item',
						'property' => 'P248',
						'snaktype' => 'value',
					}],
					'P813' => [{
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
						'datatype' => 'time',
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
	'forms' => [{
		'claims' => {
			'P898' => [{
				'mainsnak' => {
					'datavalue' => {
						'type' => 'string',
						'value' => decode_utf8('pɛs'),
					},
					'datatype' => 'string',
					'property' => 'P898',
					'snaktype' => 'value',
				},
				'rank' => 'normal',
				'type' => 'statement',
			}],
		},
		'grammaticalFeatures' => [
			'Q110786',
			'Q131105',
		],
		'id' => 'L469-F1',
		'representations' => {
			'cs' => {
				'language' => 'cs',
				'value' => 'pes',
			},
		},
	}],
	'id' => 'L469',
	'language' => 'Q9056',
	'lastrevid' => 1428556087,
	'lemmas' => {
		'cs' => {
			'language' => 'cs',
			'value' => 'pes',
		},
	},
	'lexicalCategory' => 'Q1084',
	'modified' => '2022-06-24T12:42:10Z',
	'ns' => 146,
	'pageid' => 54393954,
	'senses' => [{
		'claims' => {
			'P18' => [{
				'mainsnak' => {
					'datavalue' => {
						'type' => 'string',
						'value' => 'Canadian Inuit Dog.jpg',
					},
					'datatype' => 'commonsMedia',
					'property' => 'P18',
					'snaktype' => 'value',
				},
				'rank' => 'normal',
				'type' => 'statement',
			}],
			'P5137' => [{
				'mainsnak' => {
					'datavalue' => {
						'type' => 'wikibase-entityid',
						'value' => {
							'entity-type' => 'item',
							'id' => 'Q144',
							'numeric-id' => 144,
						},
					},
					'datatype' => 'wikibase-item',
					'property' => 'P5137',
					'snaktype' => 'value',
				},
				'rank' => 'normal',
				'type' => 'statement',
			}],
		},
		'glosses' => {
			'cs' => {
				'language' => 'cs',
				'value' => decode_utf8('psovitá šelma chovaná jako domácí zvíře'),
			},
			'en' => {
				'language' => 'en',
				'value' => 'domesticated mammal related to the wolf',
			},
		},
		'id' => 'L469-S1',
	}],
	'title' => 'Lexeme:L469',
	'type' => 'lexeme',
};
$ret = Wikibase::Datatype::Struct::Lexeme::struct2obj($struct_hr);
isa_ok($ret, 'Wikibase::Datatype::Lexeme');
is($ret->id, 'L469', 'Method id().');
is($ret->lastrevid, 1428556087, 'Method lastrevid().');
is($ret->modified, '2022-06-24T12:42:10Z', 'Method modified().');
is($ret->ns, 146, 'Method ns().');
is($ret->page_id, 54393954, 'Method page_id().');
is($ret->title, 'Lexeme:L469', 'Method title().');

# Test.
$struct_hr = {};
eval {
	Wikibase::Datatype::Struct::Lexeme::struct2obj($struct_hr);
};
is($EVAL_ERROR, "Structure isn't for 'lexeme' type.\n",
	"Structure isn't for 'lexeme' type.");
clean();

# Test.
$struct_hr = {
	'type' => 'bad',
};
eval {
	Wikibase::Datatype::Struct::Lexeme::struct2obj($struct_hr);
};
is($EVAL_ERROR, "Structure isn't for 'lexeme' type.\n",
	"Structure isn't for 'lexeme' type.");
clean();

# Test.
$struct_hr = {
	'type' => 'lexeme',
};
$ret = Wikibase::Datatype::Struct::Lexeme::struct2obj($struct_hr);
isa_ok($ret, 'Wikibase::Datatype::Lexeme');
is($ret->lastrevid, undef, 'Method lastrevid().');
is($ret->modified, undef, 'Method modified().');
is($ret->ns, 146, 'Method ns() (undefined).');
is($ret->title, undef, 'Method title().');
