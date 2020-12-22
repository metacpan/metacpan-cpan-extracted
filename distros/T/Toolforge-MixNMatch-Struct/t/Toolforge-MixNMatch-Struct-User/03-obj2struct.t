use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 4;
use Test::NoWarnings;
use Toolforge::MixNMatch::Object::User;
use Toolforge::MixNMatch::Struct::User;

# Test.
my $obj = Toolforge::MixNMatch::Object::User->new(
	'count' => 10,
	'uid' => 1,
	'username' => 'skim',
);
my $struct_hr = Toolforge::MixNMatch::Struct::User::obj2struct($obj);
is_deeply(
	$struct_hr,
	{
		'cnt' => 10,
		'uid' => 1,
		'username' => 'skim',
	},
	'Simple conversion.',
);

# Test.
eval {
	Toolforge::MixNMatch::Struct::User::obj2struct();
};
is($EVAL_ERROR, "Object doesn't exist.\n", "Object doesn't exist.");
clean();

# Test.
eval {
	Toolforge::MixNMatch::Struct::User::obj2struct('bad');
};
is($EVAL_ERROR, "Object isn't 'Toolforge::MixNMatch::Object::User'.\n",
	"Object isn't 'Toolforge::MixNMatch::Object::User'.");
clean();
