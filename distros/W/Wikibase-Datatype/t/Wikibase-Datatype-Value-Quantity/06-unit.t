use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;
use Wikibase::Datatype::Value::Quantity;

# Test.
my $obj = Wikibase::Datatype::Value::Quantity->new(
	'value' => '10',
);
my $ret = $obj->unit;
is($ret, undef, 'Get default unit().');

# Test.
$obj = Wikibase::Datatype::Value::Quantity->new(
	'unit' => 'Q190900',
	'value' => '10',
);
$ret = $obj->unit;
is($ret, 'Q190900', 'Get unit().');
