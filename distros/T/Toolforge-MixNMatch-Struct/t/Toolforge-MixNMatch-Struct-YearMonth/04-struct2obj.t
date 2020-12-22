use strict;
use warnings;

use Test::More 'tests' => 5;
use Test::NoWarnings;
use Toolforge::MixNMatch::Struct::YearMonth;

# Test.
my $struct_hr = {
	'cnt' => 10,
	'ym' => 202001
};
my $obj = Toolforge::MixNMatch::Struct::YearMonth::struct2obj($struct_hr);
isa_ok($obj, 'Toolforge::MixNMatch::Object::YearMonth');
is($obj->count, 10, 'Get count.');
is($obj->month, 1, 'Get month.');
is($obj->year, 2020, 'Get year.');
