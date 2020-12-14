use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 3;
use Test::NoWarnings;
use Wikibase::Datatype::Value;

# Test.
my $obj = Wikibase::Datatype::Value->new(
	'value' => 'foo',
	'type' => 'string',
);
isa_ok($obj, 'Wikibase::Datatype::Value');

# Test.
eval {
	Wikibase::Datatype::Value->new(
		'type' => 'string',
	);
};
is($EVAL_ERROR, "Parameter 'value' is required.\n",
	"Parameter 'value' is required.");
clean();
