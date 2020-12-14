use strict;
use warnings;

use Test::More 'tests' => 3;
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
is($ret, 11, 'Get explicit upper_bound().');
