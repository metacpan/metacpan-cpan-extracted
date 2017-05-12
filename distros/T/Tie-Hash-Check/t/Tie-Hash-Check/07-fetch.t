# Pragmas.
use strict;
use warnings;

# Modules.
use English qw(-no_match_vars);
use Error::Pure::Utils qw(clean);
use Tie::Hash::Check;
use Test::More 'tests' => 6;
use Test::NoWarnings;

# Test.
tie my %hash, 'Tie::Hash::Check', {
	'one' => 1,
	'three' => {
		'four' => 4,
	},
};
my $val = $hash{'one'};
is($val, 1, "Key 'one' exists.");
eval {
	$val = $hash{'two'};
};
is($EVAL_ERROR, "Key 'two' doesn't exist.\n", "Key 'two' doesn't exist.");
clean();
$val = $hash{'three'};
is_deeply(
	$val,
	{
		'four' => 4,
	},
	"Key 'three' exists.",
);
eval {
	$val = $hash{'three'}{'five'};
};
is($EVAL_ERROR, "Key 'three->five' doesn't exist.\n",
	"Key 'three->five' doesn't exist.");
clean();
eval {
	$val = $hash{'six'};
};
is($EVAL_ERROR, "Key 'six' doesn't exist.\n",
	"Key 'six' doesn't exist.");
clean();
