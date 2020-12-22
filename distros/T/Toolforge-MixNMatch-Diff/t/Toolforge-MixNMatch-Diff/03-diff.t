use strict;
use warnings;

use Test::More 'tests' => 8;
use Test::NoWarnings;
use Toolforge::MixNMatch::Diff;
use Toolforge::MixNMatch::Object::Catalog;
use Toolforge::MixNMatch::Object::User;

# Test.
my $t1 = Toolforge::MixNMatch::Object::Catalog->new(
	'count' => 20,
	'type' => 'Q5',
);
my $t2 = Toolforge::MixNMatch::Object::Catalog->new(
	'count' => 20,
	'type' => 'Q5',
);
my $ret = Toolforge::MixNMatch::Diff::diff($t1, $t2);
isa_ok($ret, 'Toolforge::MixNMatch::Object::Catalog', 'Test without statistics.');

# Test.
$t1 = Toolforge::MixNMatch::Object::Catalog->new(
	'count' => 20,
	'type' => 'Q5',
);
$t2 = Toolforge::MixNMatch::Object::Catalog->new(
	'count' => 20,
	'users' => [
		Toolforge::MixNMatch::Object::User->new(
			'count' => 10,
			'uid' => 1,
			'username' => 'skim',
		),
	],
	'type' => 'Q5',
);
$ret = Toolforge::MixNMatch::Diff::diff($t1, $t2);
isa_ok($ret, 'Toolforge::MixNMatch::Object::Catalog', 'Test with statistics in one catalog.');
is($ret->users->[0]->count, 10, 'Difference is 10.');

# Test.
$t1 = Toolforge::MixNMatch::Object::Catalog->new(
	'count' => 20,
	'users' => [
		Toolforge::MixNMatch::Object::User->new(
			'count' => 10,
			'uid' => 1,
			'username' => 'skim',
		),
	],
	'type' => 'Q5',
);
$t2 = Toolforge::MixNMatch::Object::Catalog->new(
	'count' => 20,
	'type' => 'Q5',
);
$ret = Toolforge::MixNMatch::Diff::diff($t1, $t2);
isa_ok($ret, 'Toolforge::MixNMatch::Object::Catalog', 'Test with statistics in one catalog.');
is($ret->users->[0]->count, 10, 'Difference is 10 (reverse catalogs).');

# Test.
$t1 = Toolforge::MixNMatch::Object::Catalog->new(
	'count' => 20,
	'users' => [
		Toolforge::MixNMatch::Object::User->new(
			'count' => 10,
			'uid' => 1,
			'username' => 'skim',
		),
	],
	'type' => 'Q5',
);
$t2 = Toolforge::MixNMatch::Object::Catalog->new(
	'count' => 20,
	'users' => [
		Toolforge::MixNMatch::Object::User->new(
			'count' => 15,
			'uid' => 1,
			'username' => 'skim',
		),
	],
	'type' => 'Q5',
);
$ret = Toolforge::MixNMatch::Diff::diff($t1, $t2);
isa_ok($ret, 'Toolforge::MixNMatch::Object::Catalog', 'Test with statistics in one catalog.');
is($ret->users->[0]->count, 5, 'Difference is 5 (diff between two values in user).');
