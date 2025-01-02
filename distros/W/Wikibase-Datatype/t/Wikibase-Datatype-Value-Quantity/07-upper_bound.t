use strict;
use warnings;

use Test::More 'tests' => 4;
use Test::NoWarnings;
use Wikibase::Datatype::Value::Quantity;

# Test.
my $obj = Wikibase::Datatype::Value::Quantity->new(
	'value' => '10',
);
my $ret = $obj->upper_bound;
is($ret, undef, 'Get default upper_bound().');

# Test.
$obj = Wikibase::Datatype::Value::Quantity->new(
	'upper_bound' => 11,
	'value' => '10',
);
$ret = $obj->upper_bound;
is($ret, 11, 'Get explicit upper_bound() (11).');

# Test.
$obj = Wikibase::Datatype::Value::Quantity->new(
	'upper_bound' => 10,
	'value' => '10',
);
$ret = $obj->upper_bound;
is($ret, 10, 'Get explicit upper_bound() (10).');
