# Pragmas.
use strict;
use warnings;

# Modules.
use English qw(-no_match_vars);
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 6;
use Test::NoWarnings;
use Video::Delay::Func;

# Test.
eval {
	Video::Delay::Func->new('');
};
is($EVAL_ERROR, "Unknown parameter ''.\n", 'Bad \'\' parameter.');
clean();

# Test.
eval {
	Video::Delay::Func->new(
		'something' => 'value',
	);
};
is($EVAL_ERROR, "Unknown parameter 'something'.\n",
	'Bad \'something\' parameter.');
clean();

# Test.
my $obj = Video::Delay::Func->new;
isa_ok($obj, 'Video::Delay::Func');
my $ret = $obj->delay;
my $right_ret = 1000 * sin(0.1);
is($ret, $right_ret, '1000 * sin(0.1)');

# Test.
eval {
	Video::Delay::Func->new(
		'func' => [],
	);
};
is($EVAL_ERROR, "Parameter 'func' must be scalar or code.\n",
	"Parameter 'func' must be scalar or code.");
clean();
