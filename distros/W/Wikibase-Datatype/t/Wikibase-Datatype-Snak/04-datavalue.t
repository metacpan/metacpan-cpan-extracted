use strict;
use warnings;

use Test::More 'tests' => 2;
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
my $ret = $obj->datavalue;
isa_ok($ret, 'Wikibase::Datatype::Value::String');
