use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 9;
use Test::NoWarnings;
use Wikibase::Datatype::MediainfoSnak;
use Wikibase::Datatype::Value::String;

# Test.
my $obj = Wikibase::Datatype::MediainfoSnak->new(
	'datavalue' => Wikibase::Datatype::Value::String->new(
		'value' => 'foo',
	),
	'property' => 'P123',
);
isa_ok($obj, 'Wikibase::Datatype::MediainfoSnak');

# Test.
eval {
	Wikibase::Datatype::MediainfoSnak->new(
		'property' => 'P123',
	);
};
is($EVAL_ERROR, "Parameter 'datavalue' is required.\n",
	"Parameter 'datavalue' is required.");
clean();

# Test.
eval {
	Wikibase::Datatype::MediainfoSnak->new(
		'datavalue' => Wikibase::Datatype::Value::String->new(
			'value' => 'foo',
		),
	);
};
is($EVAL_ERROR, "Parameter 'property' is required.\n",
	"Parameter 'property' is required.");
clean();

# Test.
eval {
	Wikibase::Datatype::MediainfoSnak->new(
		'datavalue' => 'bad',
		'property' => 'P123',
	);
};
is($EVAL_ERROR, "Parameter 'datavalue' must be a 'Wikibase::Datatype::Value' object.\n",
	"Parameter 'datavalue' is bad string.");
clean();

# Test.
eval {
	Wikibase::Datatype::MediainfoSnak->new(
		'datavalue' => Wikibase::Datatype::Value::String->new(
			'value' => 'foo',
		),
		'property' => 'P123',
		'snaktype' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'snaktype' = 'bad' isn't supported.\n",
	"Parameter 'snaktype' is bad string.");
clean();

# Test.
eval {
	Wikibase::Datatype::MediainfoSnak->new(
		'datavalue' => Wikibase::Datatype::Value::String->new(
			'value' => 'foo',
		),
		'property' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'property' must begin with 'P' and number after it.\n",
	"Parameter 'property' must begin with 'P' and number after it.");
clean();

# Test.
$obj = Wikibase::Datatype::MediainfoSnak->new(
	'property' => 'P123',
	'snaktype' => 'novalue',
);
isa_ok($obj, 'Wikibase::Datatype::MediainfoSnak');

# Test.
$obj = Wikibase::Datatype::MediainfoSnak->new(
	'property' => 'P123',
	'snaktype' => 'somevalue',
);
isa_ok($obj, 'Wikibase::Datatype::MediainfoSnak');
