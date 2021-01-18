use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 7;
use Test::NoWarnings;
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
		'ns' => 0,
		'type' => 'lexeme',
	},
	'Output of obj2struct() subroutine. Empty structure.',
);

# Test.
# TODO Complex structure.

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
		'ns' => 0,
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
