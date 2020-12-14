use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Snak;
use Wikibase::Datatype::Statement;
use Wikibase::Datatype::Value::String;

# Test.
my $obj = Wikibase::Datatype::Statement->new(
	'entity' => 'Q42',
	'snak' => Wikibase::Datatype::Snak->new(
		'datavalue' => Wikibase::Datatype::Value::String->new(
			'value' => 'foo',
		),
		'datatype' => 'string',
		'property' => 'P123',
	),
);
my $ret_ar = $obj->references;
is_deeply($ret_ar, [], 'Get default references() value.');
