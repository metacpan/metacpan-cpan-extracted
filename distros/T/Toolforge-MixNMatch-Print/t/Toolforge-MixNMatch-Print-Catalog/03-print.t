use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 7;
use Test::NoWarnings;
use Toolforge::MixNMatch::Object::Catalog;
use Toolforge::MixNMatch::Object::User;
use Toolforge::MixNMatch::Object::YearMonth;
use Toolforge::MixNMatch::Print::Catalog;

# Test.
my $obj = Toolforge::MixNMatch::Object::Catalog->new(
	'count' => 1,
	'type' => 'Q5',
);
my $ret = Toolforge::MixNMatch::Print::Catalog::print($obj);
my $right_ret = <<'END';
Type: Q5
Count: 1
END
chomp $right_ret;
is($ret, $right_ret, 'Print catalog without users and year/month stats.');

# Test.
$obj = Toolforge::MixNMatch::Object::Catalog->new(
	'count' => 10,
	'type' => 'Q5',
	'users' => [
		Toolforge::MixNMatch::Object::User->new(
			'count' => 6,
			'uid' => 1,
			'username' => 'skim',
		),
		Toolforge::MixNMatch::Object::User->new(
			'count' => 4,
			'uid' => 2,
			'username' => 'foo',
		),
	],
);
$ret = Toolforge::MixNMatch::Print::Catalog::print($obj);
$right_ret = <<'END';
Type: Q5
Count: 10
Users:
	skim (1): 6
	foo (2): 4
END
chomp $right_ret;
is($ret, $right_ret, 'Print catalog with user stats.');

# Test.
$obj = Toolforge::MixNMatch::Object::Catalog->new(
	'count' => 10,
	'type' => 'Q5',
	'year_months' => [
		Toolforge::MixNMatch::Object::YearMonth->new(
			'count' => 6,
			'month' => 1,
			'year' => 2020,
		),
		Toolforge::MixNMatch::Object::YearMonth->new(
			'count' => 4,
			'month' => 2,
			'year' => 2020,
		),
	],
);
$ret = Toolforge::MixNMatch::Print::Catalog::print($obj);
$right_ret = <<'END';
Type: Q5
Count: 10
Year/months:
	2020/1: 6
	2020/2: 4
END
chomp $right_ret;
is($ret, $right_ret, 'Print catalog with year/month stats.');

# Test.
$obj = Toolforge::MixNMatch::Object::Catalog->new(
	'count' => 10,
	'type' => 'Q5',
	'users' => [
		Toolforge::MixNMatch::Object::User->new(
			'count' => 6,
			'uid' => 1,
			'username' => 'skim',
		),
		Toolforge::MixNMatch::Object::User->new(
			'count' => 4,
			'uid' => 2,
			'username' => 'foo',
		),
	],
	'year_months' => [
		Toolforge::MixNMatch::Object::YearMonth->new(
			'count' => 6,
			'month' => 1,
			'year' => 2020,
		),
		Toolforge::MixNMatch::Object::YearMonth->new(
			'count' => 4,
			'month' => 2,
			'year' => 2020,
		),
	],
);
$ret = Toolforge::MixNMatch::Print::Catalog::print($obj);
$right_ret = <<'END';
Type: Q5
Count: 10
Year/months:
	2020/1: 6
	2020/2: 4
Users:
	skim (1): 6
	foo (2): 4
END
chomp $right_ret;
is($ret, $right_ret, 'Print catalog with user and year/month stats.');

# Test.
eval {
	Toolforge::MixNMatch::Print::Catalog::print();
};
is($EVAL_ERROR, "Object doesn't exist.\n", "Object doesn't exist.");
clean();

# Test.
eval {
	Toolforge::MixNMatch::Print::Catalog::print('bad');
};
is($EVAL_ERROR, "Object isn't 'Toolforge::MixNMatch::Object::Catalog'.\n",
	"Object isn't 'Toolforge::MixNMatch::Object::Catalog'.");
clean();
