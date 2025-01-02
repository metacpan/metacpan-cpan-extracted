use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 7;
use Test::NoWarnings;
use Wikibase::Datatype::Value::Quantity;

# Test.
my $obj = Wikibase::Datatype::Value::Quantity->new(
	'value' => '10',
);
isa_ok($obj, 'Wikibase::Datatype::Value::Quantity');

# Test.
$obj = Wikibase::Datatype::Value::Quantity->new(
	'unit' => 'Q190900',
	'value' => '10',
);
isa_ok($obj, 'Wikibase::Datatype::Value::Quantity');

# Test.
eval {
	Wikibase::Datatype::Value::Quantity->new;
};
is($EVAL_ERROR, "Parameter 'value' is required.\n",
	"Parameter 'value' is required.");
clean();

# Test.
eval {
	Wikibase::Datatype::Value::Quantity->new(
		'unit' => 'foo',
		'value' => 10,
	);
};
is($EVAL_ERROR, "Parameter 'unit' must begin with 'Q' and number after it.\n",
	"Parameter 'unit' must begin with 'Q' and number after it.");
clean();

# Test.
eval {
	Wikibase::Datatype::Value::Quantity->new(
		'lower_bound' => 11,
		'value' => 10,
	);
};
is($EVAL_ERROR, "Parameter 'lower_bound' must be less than or equal to value.\n",
	"Parameter 'lower_bound' must be less than or equal to value.");
clean();

# Test.
eval {
	Wikibase::Datatype::Value::Quantity->new(
		'upper_bound' => 9,
		'value' => 10,
	);
};
is($EVAL_ERROR, "Parameter 'upper_bound' must be greater than or equal to value.\n",
	"Parameter 'upper_bound' must be greater than or equal to value.");
clean();
