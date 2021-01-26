use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 8;
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
		'property' => 'P123',
	),
);
isa_ok($obj, 'Wikibase::Datatype::MediainfoStatement');

# Test.
eval {
	Wikibase::Datatype::MediainfoStatement->new;
};
is($EVAL_ERROR, "Parameter 'snak' is required.\n",
	"Parameter 'snak' is required.");
clean();

# Test.
eval {
	Wikibase::Datatype::MediainfoStatement->new(
		'snak' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'snak' must be a 'Wikibase::Datatype::MediainfoSnak' object.\n",
	"Parameter 'snak' must be a 'Wikibase::Datatype::MediainfoSnak' object.");
clean();

# Test.
eval {
	Wikibase::Datatype::MediainfoStatement->new(
		'rank' => 'bad',
		'snak' => Wikibase::Datatype::MediainfoSnak->new(
			'datavalue' => Wikibase::Datatype::Value::String->new(
				'value' => 'foo',
			),
			'property' => 'P123',
		),
	);
};
is($EVAL_ERROR,
	"Parameter 'rank' has bad value. Possible values are normal, preferred, deprecated.\n",
	"Parameter 'rank' has bad value.");
clean();

# Test.
$obj = Wikibase::Datatype::MediainfoStatement->new(
	'rank' => 'preferred',
	'snak' => Wikibase::Datatype::MediainfoSnak->new(
		'datavalue' => Wikibase::Datatype::Value::String->new(
			'value' => 'foo',
		),
		'property' => 'P123',
	),
);
isa_ok($obj, 'Wikibase::Datatype::MediainfoStatement');

# Test.
eval {
	Wikibase::Datatype::MediainfoStatement->new(
		'property_snaks' => 'bad',
		'snak' => Wikibase::Datatype::MediainfoSnak->new(
			'datavalue' => Wikibase::Datatype::Value::String->new(
				'value' => 'foo',
			),
			'property' => 'P123',
		),
	);
};
is($EVAL_ERROR, "Parameter 'property_snaks' must be a array.\n",
	"Parameter 'property_snaks' must be a array.");
clean();

# Test.
eval {
	Wikibase::Datatype::MediainfoStatement->new(
		'property_snaks' => ['bad'],
		'snak' => Wikibase::Datatype::MediainfoSnak->new(
			'datavalue' => Wikibase::Datatype::Value::String->new(
				'value' => 'foo',
			),
			'property' => 'P123',
		),
	);
};
is($EVAL_ERROR, "Property mediainfo snak isn't 'Wikibase::Datatype::MediainfoSnak' object.\n",
	"Property mediainfo snak isn't 'Wikibase::Datatype::MediainfoSnak' object.");
clean();
