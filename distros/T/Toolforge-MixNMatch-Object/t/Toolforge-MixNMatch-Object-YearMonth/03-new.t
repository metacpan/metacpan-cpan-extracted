use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Toolforge::MixNMatch::Object::YearMonth;

# Test.
my $obj = Toolforge::MixNMatch::Object::YearMonth->new(
	'count' => 10,
	'month' => 2,
	'year' => 2020,
);
isa_ok($obj, 'Toolforge::MixNMatch::Object::YearMonth');
