use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 10;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);
use Wikibase::Datatype::Value::Globecoordinate;
use Wikibase::Datatype::Value::Item;
use Wikibase::Datatype::Value::Monolingual;
use Wikibase::Datatype::Value::Property;
use Wikibase::Datatype::Value::Quantity;
use Wikibase::Datatype::Value::String;
use Wikibase::Datatype::Value::Time;
use Wikibase::Datatype::Print::Value;

# Test.
my $obj = Wikibase::Datatype::Value::Item->new(
	'value' => 'Q497',
);
my $ret = Wikibase::Datatype::Print::Value::print($obj);
is($ret, 'Q497', 'Get printed value for item.');

# Test.
$obj = Wikibase::Datatype::Value::Monolingual->new(
	'language' => 'cs',
	'value' => decode_utf8('Příklad.'),
);
$ret = Wikibase::Datatype::Print::Value::print($obj);
is($ret, decode_utf8('Příklad. (cs)'), 'Get printed value for monolingual.');

# Test.
$obj = Wikibase::Datatype::Value::String->new(
	'value' => 'Text',
);
$ret = Wikibase::Datatype::Print::Value::print($obj);
is($ret, 'Text', 'Get printed value for string.');

# Test.
$obj = Wikibase::Datatype::Value::Time->new(
	'value' => '+2020-09-01T00:00:00Z',
);
$ret = Wikibase::Datatype::Print::Value::print($obj);
is($ret, '1 September 2020 (Q1985727)', 'Get printed value for time.');

# Test.
$obj = Wikibase::Datatype::Value::Globecoordinate->new(
	'value' => [49.6398383, 18.1484031],
);
$ret = Wikibase::Datatype::Print::Value::print($obj);
is($ret, '(49.6398383, 18.1484031)', 'Get printed value for globecoordinate.');

# Test.
$obj = Wikibase::Datatype::Value::Property->new(
	'value' => 'P123',
);
$ret = Wikibase::Datatype::Print::Value::print($obj);
is($ret, 'P123', 'Get printed value pro property.');

# Test.
$obj = Wikibase::Datatype::Value::Quantity->new(
	'unit' => 'Q174728',
	'value' => 10,
);
$ret = Wikibase::Datatype::Print::Value::print($obj);
is($ret, '10 (Q174728)', 'Get printed value for quantity.');

# Test.
$obj = Wikibase::Datatype::Value->new(
	'value' => 'text',
	'type' => 'bad',
);
eval {
	Wikibase::Datatype::Print::Value::print($obj);
};
is($EVAL_ERROR, "Type 'bad' is unsupported.\n",
	"Type 'bad' is unsupported.");
clean();

# Test.
eval {
	Wikibase::Datatype::Print::Value::print('bad');
};
is($EVAL_ERROR, "Object isn't 'Wikibase::Datatype::Value'.\n",
	"Object isn't 'Wikibase::Datatype::Value'.");
clean();

