use strict;
use warnings;

use Test::More 'tests' => 4;
use Test::NoWarnings;
use Wikibase::Datatype::Value::Quantity;

# Test.
my $obj = Wikibase::Datatype::Value::Quantity->new(
	'value' => '10',
);
my $ret = $obj->lower_bound;
is($ret, undef, 'Get default lower_bound().');

# Test.
$obj = Wikibase::Datatype::Value::Quantity->new(
	'lower_bound' => 9,
	'value' => '10',
);
$ret = $obj->lower_bound;
is($ret, 9, 'Get explicit lower_bound() (9).');

# Test.
$obj = Wikibase::Datatype::Value::Quantity->new(
	'lower_bound' => 10,
	'value' => '10',
);
$ret = $obj->lower_bound;
is($ret, 10, 'Get explicit lower_bound() (10).');
