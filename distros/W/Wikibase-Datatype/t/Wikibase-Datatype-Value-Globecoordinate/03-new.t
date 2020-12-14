use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 7;
use Test::NoWarnings;
use Wikibase::Datatype::Value::Globecoordinate;

# Test.
my $obj = Wikibase::Datatype::Value::Globecoordinate->new(
	'value' => [49.6398383, 18.1484031],
);
isa_ok($obj, 'Wikibase::Datatype::Value::Globecoordinate');

# Test.
eval {
	Wikibase::Datatype::Value::Globecoordinate->new;
};
is($EVAL_ERROR, "Parameter 'value' is required.\n",
	"Parameter 'value' is required.");
clean();

# Test.
eval {
	Wikibase::Datatype::Value::Globecoordinate->new(
		'value' => 'bad_value',
	);
};
is($EVAL_ERROR, "Parameter 'value' must be a array.\n",
	"Parameter 'value' must be a array.");
clean();

# Test.
eval {
	Wikibase::Datatype::Value::Globecoordinate->new(
		'value' => [],
	);
};
is($EVAL_ERROR, "Parameter 'value' array must have two fields (latitude and longitude).\n",
	"Parameter 'value' array must have two fields (latitude and longitude).");
clean();

# Test.
eval {
	Wikibase::Datatype::Value::Globecoordinate->new(
		'value' => ['foo', 'bar'],
	);
};
is($EVAL_ERROR, "Parameter 'value' has bad first parameter (latitude).\n",
	"Parameter 'value' has bad first parameter (latitude).");
clean();

# Test.
eval {
	Wikibase::Datatype::Value::Globecoordinate->new(
		'value' => [10, 'bar'],
	);
};
is($EVAL_ERROR, "Parameter 'value' has bad first parameter (longitude).\n",
	"Parameter 'value' has bad first parameter (longitude).");
clean();
