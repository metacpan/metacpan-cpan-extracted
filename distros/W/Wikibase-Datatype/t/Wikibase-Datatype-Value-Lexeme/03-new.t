use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 4;
use Test::NoWarnings;
use Wikibase::Datatype::Value::Lexeme;

# Test.
my $obj = Wikibase::Datatype::Value::Lexeme->new(
	'value' => 'L42284',
);
isa_ok($obj, 'Wikibase::Datatype::Value::Lexeme');

# Test.
eval {
	Wikibase::Datatype::Value::Lexeme->new;
};
is($EVAL_ERROR, "Parameter 'value' is required.\n",
	"Parameter 'value' is required.");
clean();

# Test.
eval {
	Wikibase::Datatype::Value::Lexeme->new(
		'value' => 'foo',
	);
};
is($EVAL_ERROR, "Parameter 'value' must begin with 'L' and number after it.\n",
	"Bad 'value' parameter.");
clean();
