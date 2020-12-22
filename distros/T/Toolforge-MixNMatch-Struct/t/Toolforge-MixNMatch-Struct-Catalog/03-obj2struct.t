use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 5;
use Test::NoWarnings;
use Toolforge::MixNMatch::Object::Catalog;
use Toolforge::MixNMatch::Object::User;
use Toolforge::MixNMatch::Object::YearMonth;
use Toolforge::MixNMatch::Struct::Catalog;

# Test.
my $obj = Toolforge::MixNMatch::Object::Catalog->new(
	'count' => 10,
	'type' => 'Q5',
);
my $struct_hr = Toolforge::MixNMatch::Struct::Catalog::obj2struct($obj);
is_deeply(
	$struct_hr,
	{
		'type' => [{
			'cnt' => 10,
			'type' => 'Q5',
		}],
		'user' => [],
		'ym' => [],
	},
	'Simple conversion.',
);

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
			'count' => 2,
			'month' => 11,
			'year' => 2020,
		),
		Toolforge::MixNMatch::Object::YearMonth->new(
			'count' => 8,
			'month' => 12,
			'year' => 2020,
		),
	],
);
$struct_hr = Toolforge::MixNMatch::Struct::Catalog::obj2struct($obj);
is_deeply(
	$struct_hr,
	{
		'type' => [{
			'cnt' => 10,
			'type' => 'Q5',
		}],
		'user' => [{
			'cnt' => 6,
			'uid' => 1,
			'username' => 'skim',
		}, {
			'cnt' => 4,
			'uid' => 2,
			'username' => 'foo',
		}],
		'ym' => [{
			'cnt' => 2,
			'ym' => 202011,
		}, {
			'cnt' => 8,
			'ym' => 202012,
		}],
	},
	'Advance conversion.',
);

# Test.
eval {
	Toolforge::MixNMatch::Struct::Catalog::obj2struct();
};
is($EVAL_ERROR, "Object doesn't exist.\n", "Object doesn't exist.");
clean();

# Test.
eval {
	Toolforge::MixNMatch::Struct::Catalog::obj2struct('bad');
};
is($EVAL_ERROR, "Object isn't 'Toolforge::MixNMatch::Object::Catalog'.\n",
	"Object isn't 'Toolforge::MixNMatch::Object::Catalog'.");
clean();
