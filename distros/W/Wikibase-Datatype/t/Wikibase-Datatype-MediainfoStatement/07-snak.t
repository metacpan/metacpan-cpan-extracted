use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;
use Wikibase::Datatype::MediainfoSnak;
use Wikibase::Datatype::MediainfoStatement;
use Wikibase::Datatype::Value::String;

# Test.
my $obj = Wikibase::Datatype::MediainfoStatement->new(
	'entity' => 'Q42',
	'snak' => Wikibase::Datatype::MediainfoSnak->new(
		'datavalue' => Wikibase::Datatype::Value::String->new(
			'value' => 'foo',
		),
		'property' => 'P123',
	),
);
my $ret = $obj->snak;
is($ret->datavalue->value, 'foo', 'Get snak value.');
is($ret->property, 'P123', 'Get snak property.');
