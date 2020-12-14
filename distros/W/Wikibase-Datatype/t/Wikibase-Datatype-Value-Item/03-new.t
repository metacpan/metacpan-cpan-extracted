use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 4;
use Test::NoWarnings;
use Wikibase::Datatype::Value::Item;

# Test.
my $obj = Wikibase::Datatype::Value::Item->new(
	'value' => 'Q123',
);
isa_ok($obj, 'Wikibase::Datatype::Value::Item');

# Test.
eval {
	Wikibase::Datatype::Value::Item->new;
};
is($EVAL_ERROR, "Parameter 'value' is required.\n",
	"Parameter 'value' is required.");
clean();

# Test.
eval {
	Wikibase::Datatype::Value::Item->new(
		'value' => 'foo',
	);
};
is($EVAL_ERROR, "Parameter 'value' must begin with 'Q' and number after it.\n",
	"Bad 'value' parameter.");
clean();
