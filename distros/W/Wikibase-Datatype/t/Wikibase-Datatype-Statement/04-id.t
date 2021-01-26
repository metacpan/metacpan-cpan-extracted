use strict;
use warnings;

use Test::More 'tests' => 3;
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
my $id = $obj->id;
is($id, undef, 'Get default id() value.');

# Test.
$obj = Wikibase::Datatype::Statement->new(
	'id' => 'Q123$00C04D2A-49AF-40C2-9930-C551916887E8',
	'snak' => Wikibase::Datatype::Snak->new(
		'datavalue' => Wikibase::Datatype::Value::String->new(
			'value' => 'foo',
		),
		'datatype' => 'string',
		'property' => 'P123',
	),
);
$id = $obj->id;
is($id, 'Q123$00C04D2A-49AF-40C2-9930-C551916887E8', 'Get id() value.');
