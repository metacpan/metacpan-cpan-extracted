use strict;
use warnings;

use Test::More 'tests' => 2;
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
my $rank = $obj->rank;
is($rank, 'normal', 'Get default rank() value.');
