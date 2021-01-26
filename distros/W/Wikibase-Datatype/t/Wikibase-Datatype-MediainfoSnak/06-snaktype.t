use strict;
use warnings;

use Test::More 'tests' => 4;
use Test::NoWarnings;
use Wikibase::Datatype::MediainfoSnak;
use Wikibase::Datatype::Value::String;

# Test.
my $obj = Wikibase::Datatype::MediainfoSnak->new(
	'datavalue' => Wikibase::Datatype::Value::String->new(
		'value' => 'foo',
	),
	'property' => 'P123',
);
my $ret = $obj->snaktype;
is($ret, 'value', 'Get default snaktype() value.');

# Test.
$obj = Wikibase::Datatype::MediainfoSnak->new(
	'property' => 'P123',
	'snaktype' => 'novalue',
);
$ret = $obj->snaktype;
is($ret, 'novalue', 'Get explicit snaktype() value.');

# Test.
$obj = Wikibase::Datatype::MediainfoSnak->new(
	'property' => 'P123',
	'snaktype' => 'somevalue',
);
$ret = $obj->snaktype;
is($ret, 'somevalue', 'Get explicit snaktype() value.');
