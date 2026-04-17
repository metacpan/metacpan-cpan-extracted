use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 6;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);
use Wikibase::Datatype::Snak;
use Wikibase::Datatype::Value::Quantity;
use Wikibase::Datatype::Value::String;
use Wikibase::Datatype::Print::Snak;

# Test.
my $obj = Wikibase::Datatype::Snak->new(
	'datatype' => 'string',
	'datavalue' => Wikibase::Datatype::Value::String->new(
		'value' => '1.1',
	),
	'property' => 'P11',
);
my $ret = Wikibase::Datatype::Print::Snak::print($obj);
is($ret, 'P11: 1.1', 'Get snak value (string).');

$obj = Wikibase::Datatype::Snak->new(
	'datatype' => 'quantity',
	'datavalue' => Wikibase::Datatype::Value::Quantity->new(
		'lower_bound' => 9,
		'unit' => 'Q174728',
		'upper_bound' => 11,
		'value' => 10,
	),
	'property' => 'P11',
);
$ret = Wikibase::Datatype::Print::Snak::print($obj);
is($ret, decode_utf8('P11: 10±1 (Q174728)'), 'Get snak value (quantity with tolerance).');

# Test.
$obj = Wikibase::Datatype::Snak->new(
	'datatype' => 'string',
	'property' => 'P11',
	'snaktype' => 'novalue',
);
$ret = Wikibase::Datatype::Print::Snak::print($obj);
is($ret, 'P11: no value', 'Get snak no value.');

# Test.
$obj = Wikibase::Datatype::Snak->new(
	'datatype' => 'string',
	'property' => 'P11',
	'snaktype' => 'somevalue',
);
$ret = Wikibase::Datatype::Print::Snak::print($obj);
is($ret, 'P11: unknown value', 'Get snak somevalue.');

# Test.
eval {
	Wikibase::Datatype::Print::Snak::print('bad');
};
is($EVAL_ERROR, "Object isn't 'Wikibase::Datatype::Snak'.\n",
	"Object isn't 'Wikibase::Datatype::Snak'.");
clean();
