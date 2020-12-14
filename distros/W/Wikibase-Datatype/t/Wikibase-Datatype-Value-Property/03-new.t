use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 4;
use Test::NoWarnings;
use Wikibase::Datatype::Value::Property;

# Test.
my $obj = Wikibase::Datatype::Value::Property->new(
	'value' => 'P123',
);
isa_ok($obj, 'Wikibase::Datatype::Value::Property');

# Test.
eval {
	Wikibase::Datatype::Value::Property->new;
};
is($EVAL_ERROR, "Parameter 'value' is required.\n",
	"Parameter 'value' is required.");
clean();

# Test.
eval {
	Wikibase::Datatype::Value::Property->new(
		'value' => 'bad_property',
	);
};
is($EVAL_ERROR, "Parameter 'value' must begin with 'P' and number after it.\n",
	"Bad 'value' parameter.");
clean();
