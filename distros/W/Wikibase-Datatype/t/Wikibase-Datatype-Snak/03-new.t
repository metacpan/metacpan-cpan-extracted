use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 11;
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
isa_ok($obj, 'Wikibase::Datatype::Snak');

# Test.
eval {
	Wikibase::Datatype::Snak->new(
		'datatype' => 'string',
		'property' => 'P123',
	);
};
is($EVAL_ERROR, "Parameter 'datavalue' is required.\n",
	"Parameter 'datavalue' is required.");
clean();

# Test.
eval {
	Wikibase::Datatype::Snak->new(
		'datavalue' => Wikibase::Datatype::Value::String->new(
			'value' => 'foo',
		),
		'property' => 'P123',
	);
};
is($EVAL_ERROR, "Parameter 'datatype' is required.\n",
	"Parameter 'datatype' is required.");
clean();

# Test.
eval {
	Wikibase::Datatype::Snak->new(
		'datavalue' => Wikibase::Datatype::Value::String->new(
			'value' => 'foo',
		),
		'datatype' => 'string',
	);
};
is($EVAL_ERROR, "Parameter 'property' is required.\n",
	"Parameter 'property' is required.");
clean();

# Test.
eval {
	Wikibase::Datatype::Snak->new(
		'datavalue' => 'bad',
		'datatype' => 'string',
		'property' => 'P123',
	);
};
is($EVAL_ERROR, "Parameter 'datavalue' must be a 'Wikibase::Datatype::Value::String' object.\n",
	"Parameter 'datavalue' is bad string.");
clean();

# Test.
eval {
	Wikibase::Datatype::Snak->new(
		'datavalue' => Wikibase::Datatype::Value::String->new(
			'value' => 'foo',
		),
		'datatype' => 'bad',
		'property' => 'P123',
	);
};
is($EVAL_ERROR, "Parameter 'datatype' = 'bad' isn't supported.\n",
	"Parameter 'datatype' is bad string.");
clean();

# Test.
eval {
	Wikibase::Datatype::Snak->new(
		'datavalue' => Wikibase::Datatype::Value::String->new(
			'value' => 'foo',
		),
		'datatype' => 'string',
		'property' => 'P123',
		'snaktype' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'snaktype' = 'bad' isn't supported.\n",
	"Parameter 'snaktype' is bad string.");
clean();

# Test.
eval {
	Wikibase::Datatype::Snak->new(
		'datavalue' => Wikibase::Datatype::Value::String->new(
			'value' => 'foo',
		),
		'datatype' => 'string',
		'property' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'property' must begin with 'P' and number after it.\n",
	"Parameter 'property' must begin with 'P' and number after it.");
clean();

# Test.
$obj = Wikibase::Datatype::Snak->new(
	'datatype' => 'string',
	'property' => 'P123',
	'snaktype' => 'novalue',
);
isa_ok($obj, 'Wikibase::Datatype::Snak');

# Test.
$obj = Wikibase::Datatype::Snak->new(
	'datatype' => 'string',
	'property' => 'P123',
	'snaktype' => 'somevalue',
);
isa_ok($obj, 'Wikibase::Datatype::Snak');
