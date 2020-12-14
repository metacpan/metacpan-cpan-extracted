use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Value::Globecoordinate;

# Test.
my $obj = Wikibase::Datatype::Value::Globecoordinate->new(
	'value' => [49.6398383, 18.1484031],
);
my $ret = $obj->longitude;
is($ret, 18.1484031, 'Get longitude().');
