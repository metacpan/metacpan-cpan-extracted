use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 10;
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
isa_ok($obj, 'Wikibase::Datatype::Statement');

# Test.
eval {
	Wikibase::Datatype::Statement->new;
};
is($EVAL_ERROR, "Parameter 'snak' is required.\n",
	"Parameter 'snak' is required.");
clean();

# Test.
eval {
	Wikibase::Datatype::Statement->new(
		'snak' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'snak' must be a 'Wikibase::Datatype::Snak' object.\n",
	"Parameter 'snak' must be a 'Wikibase::Datatype::Snak' object.");
clean();

# Test.
eval {
	Wikibase::Datatype::Statement->new(
		'rank' => 'bad',
		'snak' => Wikibase::Datatype::Snak->new(
			'datavalue' => Wikibase::Datatype::Value::String->new(
				'value' => 'foo',
			),
			'datatype' => 'string',
			'property' => 'P123',
		),
	);
};
is($EVAL_ERROR,
	"Parameter 'rank' has bad value. Possible values are normal, preferred, deprecated.\n",
	"Parameter 'rank' has bad value.");
clean();

# Test.
$obj = Wikibase::Datatype::Statement->new(
	'rank' => 'preferred',
	'snak' => Wikibase::Datatype::Snak->new(
		'datavalue' => Wikibase::Datatype::Value::String->new(
			'value' => 'foo',
		),
		'datatype' => 'string',
		'property' => 'P123',
	),
);
isa_ok($obj, 'Wikibase::Datatype::Statement');

# Test.
eval {
	Wikibase::Datatype::Statement->new(
		'property_snaks' => 'bad',
		'snak' => Wikibase::Datatype::Snak->new(
			'datavalue' => Wikibase::Datatype::Value::String->new(
				'value' => 'foo',
			),
			'datatype' => 'string',
			'property' => 'P123',
		),
	);
};
is($EVAL_ERROR, "Parameter 'property_snaks' must be a array.\n",
	"Parameter 'property_snaks' must be a array.");
clean();

# Test.
eval {
	Wikibase::Datatype::Statement->new(
		'property_snaks' => ['bad'],
		'snak' => Wikibase::Datatype::Snak->new(
			'datavalue' => Wikibase::Datatype::Value::String->new(
				'value' => 'foo',
			),
			'datatype' => 'string',
			'property' => 'P123',
		),
	);
};
is($EVAL_ERROR, "Parameter 'property_snaks' with array must contain 'Wikibase::Datatype::Snak' objects.\n",
	"Parameter 'property_snaks' with array must contain 'Wikibase::Datatype::Snak' objects (bad).");
clean();

# Test.
eval {
	Wikibase::Datatype::Statement->new(
		'references' => 'bad',
		'snak' => Wikibase::Datatype::Snak->new(
			'datavalue' => Wikibase::Datatype::Value::String->new(
				'value' => 'foo',
			),
			'datatype' => 'string',
			'property' => 'P123',
		),
	);
};
is($EVAL_ERROR, "Parameter 'references' must be a array.\n",
	"Parameter 'references' must be a array.");
clean();

# Test.
eval {
	Wikibase::Datatype::Statement->new(
		'references' => ['bad'],
		'snak' => Wikibase::Datatype::Snak->new(
			'datavalue' => Wikibase::Datatype::Value::String->new(
				'value' => 'foo',
			),
			'datatype' => 'string',
			'property' => 'P123',
		),
	);
};
is($EVAL_ERROR, "Parameter 'references' with array must contain 'Wikibase::Datatype::Reference' objects.\n",
	"Parameter 'references' with array must contain 'Wikibase::Datatype::Reference' objects (bad).");
clean();
