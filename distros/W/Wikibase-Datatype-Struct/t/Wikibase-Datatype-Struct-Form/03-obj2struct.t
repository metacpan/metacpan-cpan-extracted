use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 5;
use Test::NoWarnings;
use Wikibase::Datatype::Statement;
use Wikibase::Datatype::Struct::Form;
use Wikibase::Datatype::Value::Item;
use Wikibase::Datatype::Value::Monolingual;

# Test.
my $obj = Wikibase::Datatype::Form->new(
	'grammatical_features' => [
		Wikibase::Datatype::Value::Item->new(
			'value' => 'Q163012',
		),
		Wikibase::Datatype::Value::Item->new(
			'value' => 'Q163014',
		),
	],
	'id' => 'ID',
	'representations' => [
		Wikibase::Datatype::Value::Monolingual->new(
			'language' => 'en',
			'value' => 'Representation en',
		),
		Wikibase::Datatype::Value::Monolingual->new(
			'language' => 'cs',
			'value' => 'Representation cs',
		),
	],
	'statements' => [
		Wikibase::Datatype::Statement->new(
			# instance of (P31) human (Q5)
			'snak' => Wikibase::Datatype::Snak->new(
				'datatype' => 'wikibase-item',
				'datavalue' => Wikibase::Datatype::Value::Item->new(
					'value' => 'Q5',
				),
				'property' => 'P31',
			),
		),
		Wikibase::Datatype::Statement->new(
			# instance of (P31) programmer (Q5482740)
			'snak' => Wikibase::Datatype::Snak->new(
				'datatype' => 'wikibase-item',
				'datavalue' => Wikibase::Datatype::Value::Item->new(
					'value' => 'Q5482740',
				),
				'property' => 'P31',
			),
		),
	],
);
my $ret_hr = Wikibase::Datatype::Struct::Form::obj2struct($obj,
	'http://test.wikidata.org/entity/');
is_deeply(
	$ret_hr,
	{
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
			}, {
				'mainsnak' => {
					'datatype' => 'wikibase-item',
					'datavalue' => {
						'type' => 'wikibase-entityid',
						'value' => {
							'entity-type' => 'item',
							'id' => 'Q5482740',
							'numeric-id' => 5482740,
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
				'value' => 'Representation cs',
			},
			'en' => {
				'language' => 'en',
				'value' => 'Representation en',
			},
		},
	},
	'Output of obj2struct() subroutine.',
);

# Test.
eval {
	Wikibase::Datatype::Struct::Form::obj2struct('bad');
};
is($EVAL_ERROR, "Object isn't 'Wikibase::Datatype::Form'.\n",
	"Object isn't 'Wikibase::Datatype::Form'.");
clean();

# Test.
$obj = Wikibase::Datatype::Form->new(
	'id' => 'ID',
);
eval {
	Wikibase::Datatype::Struct::Form::obj2struct($obj);
};
is($EVAL_ERROR, "Base URI is required.\n", 'Base URI is required.');
clean();

# Test.
eval {
	Wikibase::Datatype::Struct::Form::obj2struct();
};
is($EVAL_ERROR, "Object doesn't exist.\n", "Object doesn't exist.");
clean();
