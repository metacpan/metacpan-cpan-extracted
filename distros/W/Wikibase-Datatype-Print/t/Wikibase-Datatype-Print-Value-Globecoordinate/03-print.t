use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 3;
use Test::NoWarnings;
use Wikibase::Datatype::Value::Globecoordinate;
use Wikibase::Datatype::Print::Value::Globecoordinate;

# Test.
my $obj = Wikibase::Datatype::Value::Globecoordinate->new(
	'value' => [49.6398383, 18.1484031],
);
my $ret = Wikibase::Datatype::Print::Value::Globecoordinate::print($obj);
is($ret, '(49.6398383, 18.1484031)', 'Get printed value.');

# Test.
eval {
	Wikibase::Datatype::Print::Value::Globecoordinate::print('bad');
};
is($EVAL_ERROR, "Object isn't 'Wikibase::Datatype::Value::Globecoordinate'.\n",
	"Object isn't 'Wikibase::Datatype::Value::Globecoordinate'.");
clean();
