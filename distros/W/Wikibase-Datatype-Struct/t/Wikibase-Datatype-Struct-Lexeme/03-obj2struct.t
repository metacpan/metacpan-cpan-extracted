use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 8;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Lexeme::Wikidata::DogCzechNoun;
use Unicode::UTF8 qw(decode_utf8);
use Wikibase::Datatype::Lexeme;
use Wikibase::Datatype::Snak;
use Wikibase::Datatype::Statement;
use Wikibase::Datatype::Struct::Lexeme;

# Test.
my $obj = Wikibase::Datatype::Lexeme->new;
my $ret_hr = Wikibase::Datatype::Struct::Lexeme::obj2struct($obj,
	'http://test.wikidata.org/entity/');
is_deeply(
	$ret_hr,
	{
		'ns' => 146,
		'type' => 'lexeme',
	},
	'Output of obj2struct() subroutine. Empty structure.',
);

# Test.
$obj = Test::Shared::Fixture::Wikibase::Datatype::Lexeme::Wikidata::DogCzechNoun->new;
$ret_hr = Wikibase::Datatype::Struct::Lexeme::obj2struct($obj,
	'http://test.wikidata.org/entity/');
is_deeply(
	$ret_hr,
	{
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
		'language' => 'Q9056',
		'lastrevid' => 1428556087,
		'lemmas' => {
			'cs' => {
				'language' => 'cs',
				'value' => 'pes',
			},
		},
		'id' => 'L469',
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
	},
	'Output of obj2struct() subroutine. Complex structure.',
);

# Test.
eval {
	Wikibase::Datatype::Struct::Lexeme::obj2struct('bad');
};
is($EVAL_ERROR, "Object isn't 'Wikibase::Datatype::Lexeme'.\n",
	"Object isn't 'Wikibase::Datatype::Lexeme'.");
clean();

# Test.
eval {
	Wikibase::Datatype::Struct::Lexeme::obj2struct();
};
is($EVAL_ERROR, "Object doesn't exist.\n", "Object doesn't exist.");
clean();

# Test.
$obj = Wikibase::Datatype::Lexeme->new;
eval {
	Wikibase::Datatype::Struct::Lexeme::obj2struct($obj);
};
is($EVAL_ERROR, "Base URI is required.\n", 'Base URI is required.');
clean();

# Test.
$obj = Wikibase::Datatype::Lexeme->new(
	'statements' => [
		Wikibase::Datatype::Statement->new(
			'snak' => Wikibase::Datatype::Snak->new(
				'datatype' => 'string',
				'datavalue' => Wikibase::Datatype::Value::String->new(
					'value' => '1.1',
				),
				'property' => 'P11',
			),
			'rank' => 'normal',
		),
		Wikibase::Datatype::Statement->new(
			'snak' => Wikibase::Datatype::Snak->new(
				'datatype' => 'string',
				'property' => 'P11',
				'snaktype' => 'novalue',
			),
			'rank' => 'normal',
		),
	],
);
$ret_hr = Wikibase::Datatype::Struct::Lexeme::obj2struct($obj,
	'http://test.wikidata.org/entity/');
is_deeply(
	$ret_hr,
	{
		'claims' => {
			'P11' => [{
				'mainsnak' => {
					'datatype' => 'string',
					'datavalue' => {
						'type' => 'string',
						'value' => '1.1',
					},
					'property' => 'P11',
					'snaktype' => 'value',
				},
				'rank' => 'normal',
				'type' => 'statement',
			}, {
				'mainsnak' => {
					'datatype' => 'string',
					'property' => 'P11',
					'snaktype' => 'novalue',
				},
				'rank' => 'normal',
				'type' => 'statement',
			}],
		},
		'ns' => 146,
		'type' => 'lexeme',
	},
	'Output of obj2struct() subroutine. Two claims for one property.',
);

# Test.
$obj = Wikibase::Datatype::Lexeme->new(
	'ns' => undef,
);
$ret_hr = Wikibase::Datatype::Struct::Lexeme::obj2struct($obj,
	'http://test.wikidata.org/entity/');
is_deeply(
	$ret_hr,
	{
		'type' => 'lexeme',
	},
	'Output of obj2struct() subroutine. Undefined name space.',
);
