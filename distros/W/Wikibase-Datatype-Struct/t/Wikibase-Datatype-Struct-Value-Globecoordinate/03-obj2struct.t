use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 6;
use Test::NoWarnings;
use Wikibase::Datatype::Value::Globecoordinate;
use Wikibase::Datatype::Struct::Value::Globecoordinate;

# Test.
my $obj = Wikibase::Datatype::Value::Globecoordinate->new(
	'value' => [10.1, 20.1],
);
my $ret_hr = Wikibase::Datatype::Struct::Value::Globecoordinate::obj2struct($obj,
	'http://test.wikidata.org/entity/');
is_deeply(
	$ret_hr,
	{
		'value' => {
			'altitude' => 'null',
			'globe' => 'http://test.wikidata.org/entity/Q2',
			'latitude' => 10.1,
			'longitude' => 20.1,
			'precision' => '1e-07',
		},
		'type' => 'globecoordinate',
	},
	'Output of obj2struct() subroutine.',
);

# Test.
eval {
	Wikibase::Datatype::Struct::Value::Globecoordinate::obj2struct('bad');
};
is($EVAL_ERROR, "Object isn't 'Wikibase::Datatype::Value::Globecoordinate'.\n",
	"Object isn't 'Wikibase::Datatype::Value::Globecoordinate'.");
clean();

# Test.
$obj = Wikibase::Datatype::Value::Globecoordinate->new(
	'altitude' => 100,
	'value' => [10.1, 20.1],
);
$ret_hr = Wikibase::Datatype::Struct::Value::Globecoordinate::obj2struct($obj,
	'http://test.wikidata.org/entity/');
is_deeply(
	$ret_hr,
	{
		'value' => {
			'altitude' => 100,
			'globe' => 'http://test.wikidata.org/entity/Q2',
			'latitude' => 10.1,
			'longitude' => 20.1,
			'precision' => '1e-07',
		},
		'type' => 'globecoordinate',
	},
	'Output of obj2struct() subroutine. With altitude.',
);

# Test.
eval {
	Wikibase::Datatype::Struct::Value::Globecoordinate::obj2struct();
};
is($EVAL_ERROR, "Object doesn't exist.\n", "Object doesn't exist.");
clean();

# Test.
$obj = Wikibase::Datatype::Value::Globecoordinate->new(
	'altitude' => 100,
	'value' => [10.1, 20.1],
);
eval {
	Wikibase::Datatype::Struct::Value::Globecoordinate::obj2struct($obj);
};
is($EVAL_ERROR, "Base URI is required.\n", 'Base URI is required.');
clean();
