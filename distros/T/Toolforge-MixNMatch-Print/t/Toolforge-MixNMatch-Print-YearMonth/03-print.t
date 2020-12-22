use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 4;
use Test::NoWarnings;
use Toolforge::MixNMatch::Object::YearMonth;
use Toolforge::MixNMatch::Print::YearMonth;

# Test.
my $obj = Toolforge::MixNMatch::Object::YearMonth->new(
	'count' => 10,
	'month' => 11,
	'year' => '2020',
);
my $ret = Toolforge::MixNMatch::Print::YearMonth::print($obj);
is($ret, '2020/11: 10', 'Print year/month.');

# Test.
eval {
	Toolforge::MixNMatch::Print::YearMonth::print();
};
is($EVAL_ERROR, "Object doesn't exist.\n", "Object doesn't exist.");
clean();

# Test.
eval {
	Toolforge::MixNMatch::Print::YearMonth::print('bad');
};
is($EVAL_ERROR, "Object isn't 'Toolforge::MixNMatch::Object::YearMonth'.\n",
	"Object isn't 'Toolforge::MixNMatch::Object::YearMonth'.");
clean();
