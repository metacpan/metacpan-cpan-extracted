use strict;
use warnings;

use Test::More 'tests' => 4;
use Test::NoWarnings;
use Wikibase::Datatype::Snak;
use Wikibase::Datatype::Statement;
use Wikibase::Datatype::Value::String;

# Test.
my $obj = Wikibase::Datatype::Statement->new(
	'snak' => Wikibase::Datatype::Snak->new(
		'datavalue' => Wikibase::Datatype::Value::String->new(
			'value' => 'foo',
		),
		'datatype' => 'string',
		'property' => 'P123',
	),
);
my $ret = $obj->snak;
is($ret->datavalue->value, 'foo', 'Get snak value.');
is($ret->datatype, 'string', 'Get snak type.');
is($ret->property, 'P123', 'Get snak property.');
