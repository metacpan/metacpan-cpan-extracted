use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;
use Wikibase::Datatype::Snak;
use Wikibase::Datatype::Value::String;

# Test.
my $obj = Wikibase::Datatype::Snak->new(
	'datavalue' => Wikibase::Datatype::Value::String->new(
		'value' => 'foo',
	),
	'datatype' => 'string',
	'property' => 'P123',
);
my $ret = $obj->snaktype;
is($ret, 'value', 'Get default snaktype() value.');

# Test.
$obj = Wikibase::Datatype::Snak->new(
	'datavalue' => Wikibase::Datatype::Value::String->new(
		'value' => 'foo',
	),
	'datatype' => 'string',
	'property' => 'P123',
	'snaktype' => 'novalue',
);
$ret = $obj->snaktype;
is($ret, 'novalue', 'Get explicit snaktype() value.');
