use strict;
use warnings;

use Test::More 'tests' => 11;
use Test::NoWarnings;
use Toolforge::MixNMatch::Struct::Catalog;

# Test.
my $struct_hr = {
	'type' => [{
		'cnt' => 10,
		'type' => 'Q5',
	}],
	'user' => [],
	'ym' => [],
};
my $obj = Toolforge::MixNMatch::Struct::Catalog::struct2obj($struct_hr);
isa_ok($obj, 'Toolforge::MixNMatch::Object::Catalog');
is($obj->count, 10, 'Get count.');
is($obj->type, 'Q5', 'Get type.');
is(@{$obj->users}, 0, 'Get number of user statistics.');
is(@{$obj->year_months}, 0, 'Get number of year/month statistics.');

# Test.
$struct_hr = {
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
};
$obj = Toolforge::MixNMatch::Struct::Catalog::struct2obj($struct_hr);
isa_ok($obj, 'Toolforge::MixNMatch::Object::Catalog');
is($obj->count, 10, 'Get count.');
is($obj->type, 'Q5', 'Get type.');
is(@{$obj->users}, 2, 'Get number of user statistics.');
is(@{$obj->year_months}, 2, 'Get number of year/month statistics.');
