use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 12;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);
use Wikibase::Datatype::Value::Globecoordinate;
use Wikibase::Datatype::Value::Item;
use Wikibase::Datatype::Value::Monolingual;
use Wikibase::Datatype::Value::Property;
use Wikibase::Datatype::Value::Quantity;
use Wikibase::Datatype::Value::Sense;
use Wikibase::Datatype::Value::String;
use Wikibase::Datatype::Value::Time;
use Wikibase::Datatype::Struct::Value;

# Test.
my $obj = Wikibase::Datatype::Value::Globecoordinate->new(
	'value' => [10.1, 20.1],
);
my $ret_hr = Wikibase::Datatype::Struct::Value::obj2struct($obj,
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
	'Item: Output of obj2struct() subroutine.',
);

# Test.
$obj = Wikibase::Datatype::Value::Item->new(
	'value' => 'Q497',
);
$ret_hr = Wikibase::Datatype::Struct::Value::obj2struct($obj);
is_deeply(
	$ret_hr,
	{
		'value' => {
			'entity-type' => 'item',
			'id' => 'Q497',
			'numeric-id' => 497,
		},
		'type' => 'wikibase-entityid',
	},
	'Item: Output of obj2struct() subroutine.',
);

# Test.
$obj = Wikibase::Datatype::Value::Monolingual->new(
	'language' => 'cs',
	'value' => decode_utf8('Příklad.'),
);
$ret_hr = Wikibase::Datatype::Struct::Value::obj2struct($obj);
is_deeply(
	$ret_hr,
	{
		'value' => {
			'language' => 'cs',
			'text' => decode_utf8('Příklad.'),
		},
		'type' => 'monolingualtext',
	},
	'Monolingual: Output of obj2struct() subroutine.',
);

# Test.
$obj = Wikibase::Datatype::Value::Property->new(
	'value' => 'P123',
);
$ret_hr = Wikibase::Datatype::Struct::Value::obj2struct($obj, 'https://test.wikidata.org/entity/');
is_deeply(
	$ret_hr,
	{
		'value' => {
			'entity-type' => 'property',
			'id' => 'P123',
			'numeric-id' => 123,
		},
		'type' => 'wikibase-entityid',
	},
	'Quantity: Output of obj2struct() subroutine.',
);

# Test.
$obj = Wikibase::Datatype::Value::Quantity->new(
	'unit' => 'Q123',
	'value' => 10,
);
$ret_hr = Wikibase::Datatype::Struct::Value::obj2struct($obj, 'https://test.wikidata.org/entity/');
is_deeply(
	$ret_hr,
	{
		'value' => {
			'amount' => '+10',
			'unit' => 'https://test.wikidata.org/entity/Q123',
		},
		'type' => 'quantity',
	},
	'Quantity: Output of obj2struct() subroutine.',
);

# Test.
$obj = Wikibase::Datatype::Value::Sense->new(
	'value' => 'L34727-S1',
);
$ret_hr = Wikibase::Datatype::Struct::Value::obj2struct($obj);
is_deeply(
	$ret_hr,
	{
		'value' => {
			'entity-type' => 'sense',
			'id' => 'L34727-S1',
		},
		'type' => 'wikibase-entityid',
	},
	'Sense: Output of obj2struct() subroutine.',
);

# Test.
$obj = Wikibase::Datatype::Value::String->new(
	'value' => 'Text',
);
$ret_hr = Wikibase::Datatype::Struct::Value::obj2struct($obj);
is_deeply(
	$ret_hr,
	{
		'value' => 'Text',
		'type' => 'string',
	},
	'String: Output of obj2struct() subroutine.',
);

# Test.
$obj = Wikibase::Datatype::Value::Time->new(
	'value' => '+2020-09-01T00:00:00Z',
);
$ret_hr = Wikibase::Datatype::Struct::Value::obj2struct($obj, 'https://www.wikidata.org/entity/');
is_deeply(
	$ret_hr,
	{
		'value' => {
			'after' => 0,
			'before' => 0,
			'calendarmodel' => 'https://www.wikidata.org/entity/Q1985727',
			'precision' => 11,
			'time' => '+2020-09-01T00:00:00Z',
			'timezone' => 0,
		},
		'type' => 'time',
	},
	'Time: Output of obj2struct() subroutine.',
);

# Test.
$obj = Wikibase::Datatype::Value->new(
	'value' => 'text',
	'type' => 'bad',
);
eval {
	Wikibase::Datatype::Struct::Value::obj2struct($obj);
};
is($EVAL_ERROR, "Type 'bad' is unsupported.\n",
	"Type 'bad' is unsupported.");
clean();

# Test.
eval {
	Wikibase::Datatype::Struct::Value::obj2struct('bad');
};
is($EVAL_ERROR, "Object isn't 'Wikibase::Datatype::Value'.\n",
	"Object isn't 'Wikibase::Datatype::Value'.");
clean();

# Test.
eval {
	Wikibase::Datatype::Struct::Value::obj2struct();
};
is($EVAL_ERROR, "Object doesn't exist.\n", "Object doesn't exist.");
clean();
