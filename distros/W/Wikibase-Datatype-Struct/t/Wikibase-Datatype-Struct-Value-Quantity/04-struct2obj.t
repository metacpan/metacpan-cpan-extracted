use strict;
use warnings;

use Test::More 'tests' => 15;
use Test::NoWarnings;
use Wikibase::Datatype::Struct::Value::Quantity;

# Test.
my $struct_hr = {
	'value' => {
		'amount' => '+10',
		'unit' => 1,
	},
	'type' => 'quantity',
};
my $ret = Wikibase::Datatype::Struct::Value::Quantity::struct2obj($struct_hr);
isa_ok($ret, 'Wikibase::Datatype::Value::Quantity');
is($ret->value, 10, 'Method value().');
is($ret->type, 'quantity', 'Method type().');
is($ret->unit, undef, 'Method unit().');

# Test.
$struct_hr = {
	'value' => {
		'amount' => '+10',
		'unit' => 'https://test.wikidata.org/entity/Q123',
	},
	'type' => 'quantity',
};
$ret = Wikibase::Datatype::Struct::Value::Quantity::struct2obj($struct_hr);
isa_ok($ret, 'Wikibase::Datatype::Value::Quantity');
is($ret->value, 10, 'Method value().');
is($ret->type, 'quantity', 'Method type().');
is($ret->unit, 'Q123', 'Method unit().');

# Test.
$struct_hr = {
	'value' => {
		'amount' => '+10',
		'lowerBound' => '+9',
		'unit' => 'https://test.wikidata.org/entity/Q123',
		'upperBound' => '+11',
	},
	'type' => 'quantity',
};
$ret = Wikibase::Datatype::Struct::Value::Quantity::struct2obj($struct_hr);
isa_ok($ret, 'Wikibase::Datatype::Value::Quantity');
is($ret->value, 10, 'Method value().');
is($ret->type, 'quantity', 'Method type().');
is($ret->unit, 'Q123', 'Method unit().');
is($ret->lower_bound, 9, 'Method lower_bound().');
is($ret->upper_bound, 11, 'Method upper_bound().');
