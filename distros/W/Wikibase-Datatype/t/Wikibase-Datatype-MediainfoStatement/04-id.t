use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;
use Wikibase::Datatype::MediainfoSnak;
use Wikibase::Datatype::MediainfoStatement;
use Wikibase::Datatype::Value::String;

# Test.
my $obj = Wikibase::Datatype::MediainfoStatement->new(
	'snak' => Wikibase::Datatype::MediainfoSnak->new(
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
$obj = Wikibase::Datatype::MediainfoStatement->new(
	'id' => 'M123$00C04D2A-49AF-40C2-9930-C551916887E8',
	'snak' => Wikibase::Datatype::MediainfoSnak->new(
		'datavalue' => Wikibase::Datatype::Value::String->new(
			'value' => 'foo',
		),
		'datatype' => 'string',
		'property' => 'P123',
	),
);
$id = $obj->id;
is($id, 'M123$00C04D2A-49AF-40C2-9930-C551916887E8', 'Get id() value.');
