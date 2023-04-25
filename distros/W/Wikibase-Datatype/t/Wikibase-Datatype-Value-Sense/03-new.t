use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 4;
use Test::NoWarnings;
use Wikibase::Datatype::Value::Sense;

# Test.
my $obj = Wikibase::Datatype::Value::Sense->new(
	'value' => 'L34727-S1',
);
isa_ok($obj, 'Wikibase::Datatype::Value::Sense');

# Test.
eval {
	Wikibase::Datatype::Value::Sense->new;
};
is($EVAL_ERROR, "Parameter 'value' is required.\n",
	"Parameter 'value' is required.");
clean();

# Test.
eval {
	Wikibase::Datatype::Value::Sense->new(
		'value' => 'bad_sense',
	);
};
is($EVAL_ERROR, "Parameter 'value' must begin with 'L' and number, dash, S and number after it.\n",
	"Bad 'value' parameter.");
clean();
