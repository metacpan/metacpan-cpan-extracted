use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 3;
use Test::NoWarnings;
use Wikibase::Datatype::Value::String;

# Test.
my $obj = Wikibase::Datatype::Value::String->new(
	'value' => 'text',
);
isa_ok($obj, 'Wikibase::Datatype::Value::String');

# Test.
eval {
	Wikibase::Datatype::Value::String->new;
};
is($EVAL_ERROR, "Parameter 'value' is required.\n",
	"Parameter 'value' is required.");
clean();
