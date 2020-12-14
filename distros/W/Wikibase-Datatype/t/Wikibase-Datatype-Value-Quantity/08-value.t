use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;
use Wikibase::Datatype::Value::Quantity;

# Test.
my $obj = Wikibase::Datatype::Value::Quantity->new(
	'value' => '10',
);
my $ret = $obj->value;
is($ret, '10', 'Get positive value().');

# Test.
$obj = Wikibase::Datatype::Value::Quantity->new(
	'value' => '-10',
);
$ret = $obj->value;
is($ret, '-10', 'Get negative value().');
