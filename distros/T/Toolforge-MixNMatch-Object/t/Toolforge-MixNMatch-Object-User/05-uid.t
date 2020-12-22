use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Toolforge::MixNMatch::Object::User;

# Test.
my $obj = Toolforge::MixNMatch::Object::User->new(
	'count' => 10,
	'uid' => 1,
	'username' => 'skim',
);
is($obj->uid, 1, 'Get user UID.');
