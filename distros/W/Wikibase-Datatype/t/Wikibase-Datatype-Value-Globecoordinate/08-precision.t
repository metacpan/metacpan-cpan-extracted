use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;
use Wikibase::Datatype::Value::Globecoordinate;

# Test.
my $obj = Wikibase::Datatype::Value::Globecoordinate->new(
	'value' => [49.6398383, 18.1484031],
);
my $ret = $obj->precision;
is($ret, '1e-07', 'Get default precision().');

# Test.
$obj = Wikibase::Datatype::Value::Globecoordinate->new(
	'precision' => 1,
	'value' => [49.6398383, 18.1484031],
);
$ret = $obj->precision;
is($ret, 1, 'Get explicit precision().');
