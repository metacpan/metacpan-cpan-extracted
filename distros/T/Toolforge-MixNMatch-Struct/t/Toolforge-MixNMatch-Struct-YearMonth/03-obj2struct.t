use strict;

use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 4;
use Test::NoWarnings;
use Toolforge::MixNMatch::Object::YearMonth;
use Toolforge::MixNMatch::Struct::YearMonth;

# Test.
my $obj = Toolforge::MixNMatch::Object::YearMonth->new(
	'count' => 10,
	'month' => 1,
	'year' => 2020,
);
my $struct_hr = Toolforge::MixNMatch::Struct::YearMonth::obj2struct($obj);
is_deeply(
	$struct_hr,
	{
		'cnt' => 10,
		'ym' => 202001,
	},
	'Simple conversion.',
);

# Test.
eval {
	Toolforge::MixNMatch::Struct::YearMonth::obj2struct();
};
is($EVAL_ERROR, "Object doesn't exist.\n", "Object doesn't exist.");
clean();

# Test.
eval {
	Toolforge::MixNMatch::Struct::YearMonth::obj2struct('bad');
};
is($EVAL_ERROR, "Object isn't 'Toolforge::MixNMatch::Object::YearMonth'.\n",
	"Object isn't 'Toolforge::MixNMatch::Object::YearMonth'.");
clean();
