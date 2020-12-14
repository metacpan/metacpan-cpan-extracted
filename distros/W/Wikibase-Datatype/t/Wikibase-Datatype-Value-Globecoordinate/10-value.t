use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Value::Globecoordinate;

# Test.
my $obj = Wikibase::Datatype::Value::Globecoordinate->new(
	'value' => [49.6398383, 18.1484031],
);
my $ret_ar = $obj->value;
is_deeply($ret_ar, [49.6398383, 18.1484031], 'Get value().');
