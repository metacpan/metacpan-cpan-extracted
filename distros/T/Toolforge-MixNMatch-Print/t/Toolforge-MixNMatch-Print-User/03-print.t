use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 4;
use Test::NoWarnings;
use Toolforge::MixNMatch::Object::User;
use Toolforge::MixNMatch::Print::User;

# Test.
my $obj = Toolforge::MixNMatch::Object::User->new(
	'count' => 10,
	'uid' => 1,
	'username' => 'skim',
);
my $ret = Toolforge::MixNMatch::Print::User::print($obj);
is($ret, 'skim (1): 10', 'Print user.');

# Test.
eval {
	Toolforge::MixNMatch::Print::User::print();
};
is($EVAL_ERROR, "Object doesn't exist.\n", "Object doesn't exist.");
clean();

# Test.
eval {
	Toolforge::MixNMatch::Print::User::print('bad');
};
is($EVAL_ERROR, "Object isn't 'Toolforge::MixNMatch::Object::User'.\n",
	"Object isn't 'Toolforge::MixNMatch::Object::User'.");
clean();
