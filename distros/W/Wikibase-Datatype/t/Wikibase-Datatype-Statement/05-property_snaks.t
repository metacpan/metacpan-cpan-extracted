use strict;
use warnings;

use Test::More 'tests' => 2;
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
my $ret_ar = $obj->property_snaks;
is_deeply($ret_ar, [], 'Get default property_snaks() value.');
