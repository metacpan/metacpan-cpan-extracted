use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 7;
use Test::NoWarnings;
use Wikibase::Datatype::Value::Quantity;
use Wikibase::Datatype::Struct::Value::Quantity;

# Test.
my $obj = Wikibase::Datatype::Value::Quantity->new(
	'value' => 10,
);
my $ret_hr = Wikibase::Datatype::Struct::Value::Quantity::obj2struct($obj,
	'https://test.wikidata.org/entity');
is_deeply(
	$ret_hr,
	{
		'value' => {
			'amount' => '+10',
			'unit' => 1,
		},
		'type' => 'quantity',
	},
	'Output of obj2struct() subroutine.',
);

# Test.
$obj = Wikibase::Datatype::Value::Quantity->new(
	'unit' => 'Q123',
	'value' => 10,
);
$ret_hr = Wikibase::Datatype::Struct::Value::Quantity::obj2struct($obj,
	'https://test.wikidata.org/entity/');
is_deeply(
	$ret_hr,
	{
		'value' => {
			'amount' => '+10',
			'unit' => 'https://test.wikidata.org/entity/Q123',
		},
		'type' => 'quantity',
	},
	'Output of obj2struct() subroutine.',
);

# Test.
$obj = Wikibase::Datatype::Value::Quantity->new(
	'lower_bound' => 9,
	'unit' => 'Q123',
	'value' => 10,
	'upper_bound' => 11,
);
$ret_hr = Wikibase::Datatype::Struct::Value::Quantity::obj2struct($obj,
	'https://test.wikidata.org/entity/');
is_deeply(
	$ret_hr,
	{
		'value' => {
			'amount' => '+10',
			'lowerBound' => '+9',
			'unit' => 'https://test.wikidata.org/entity/Q123',
			'upperBound' => '+11',
		},
		'type' => 'quantity',
	},
	'Output of obj2struct() subroutine.',
);

# Test.
eval {
	Wikibase::Datatype::Struct::Value::Quantity::obj2struct('bad');
};
is($EVAL_ERROR, "Object isn't 'Wikibase::Datatype::Value::Quantity'.\n",
	"Object isn't 'Wikibase::Datatype::Value::Quantity'.");
clean();

# Test.
$obj = Wikibase::Datatype::Value::Quantity->new(
	'value' => 10,
);
eval {
	Wikibase::Datatype::Struct::Value::Quantity::obj2struct($obj);
};
is($EVAL_ERROR, "Base URI is required.\n", 'Base URI is required.');
clean();

# Test.
eval {
	Wikibase::Datatype::Struct::Value::Quantity::obj2struct();
};
is($EVAL_ERROR, "Object doesn't exist.\n", "Object doesn't exist.");
clean();
