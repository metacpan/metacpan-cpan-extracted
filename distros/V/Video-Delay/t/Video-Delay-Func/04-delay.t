# Pragmas.
use strict;
use warnings;

# Modules.
use English qw(-no_match_vars);
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 8;
use Test::NoWarnings;
use Video::Delay::Func;

# Test.
my $obj = Video::Delay::Func->new(
	'func' => 't',
	'incr' => 1,
);
my $ret = $obj->delay;
is($ret, 1, "First item of 't' function with incerement '1'.");
$ret = $obj->delay;
is($ret, 2, "Second item of 't' function with increment '1'.");
$ret = $obj->delay;
is($ret, 3, "Third item of 't' function with increment '1'.");

# Test.
$obj = Video::Delay::Func->new(
	'func' => 'foo',
);
eval {
	$obj->delay;
};
is($EVAL_ERROR, "Error in function.\n", 'Error in function.');
clean();

# Test.
$obj = Video::Delay::Func->new(
	'func' => sub {
		my $t = shift;
		return $t;
	},
	'incr' => 1,
);
$ret = $obj->delay;
is($ret, 1, "First item of callback with 't' function with incerement '1'.");
$ret = $obj->delay;
is($ret, 2, "Second item of callback with 't' function with increment '1'.");
$ret = $obj->delay;
is($ret, 3, "Third item of callback with 't' function with increment '1'.");
