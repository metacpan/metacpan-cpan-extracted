use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 5;
use Test::NoWarnings;
use Toolforge::MixNMatch::Object::User;

# Test.
my $obj = Toolforge::MixNMatch::Object::User->new(
	'count' => 1,
	'uid' => 1,
	'username' => 'skim',
);
isa_ok($obj, 'Toolforge::MixNMatch::Object::User');

# Test.
eval {
	Toolforge::MixNMatch::Object::User->new(
		'count' => 1,
		'uid' => 1,
	);
};
is($EVAL_ERROR, "Parameter 'username' is required.\n",
	"Parameter 'username' is required.");
clean();

# Test.
eval {
	Toolforge::MixNMatch::Object::User->new(
		'count' => 1,
		'username' => 'skim',
	);
};
is($EVAL_ERROR, "Parameter 'uid' is required.\n",
	"Parameter 'uid' is required.");
clean();

# Test.
eval {
	Toolforge::MixNMatch::Object::User->new(
		'uid' => 1,
		'username' => 'skim',
	);
};
is($EVAL_ERROR, "Parameter 'count' is required.\n",
	"Parameter 'count' is required.");
clean();
