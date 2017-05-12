# Pragmas.
use strict;
use warnings;

# Modules.
use English qw(-no_match_vars);
use Error::Pure::Utils qw(clean);
use Tie::Hash::Check;
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
tie my %hash, 'Tie::Hash::Check', {
	'one' => 1,
	'two' => 2,
};
my $keys = keys %hash;
ok($hash{'one'}, "Key 'one' exists.");
ok($hash{'two'}, "Key 'two' exists.");
delete $hash{'one'};
eval {
	my $val = $hash{'one'};
};
is($EVAL_ERROR, "Key 'one' doesn't exist.\n", "Key 'one' doesn't exist.");
delete $hash{'two'};
eval {
	my $val = $hash{'two'};
};
is($EVAL_ERROR, "Key 'two' doesn't exist.\n", "Key 'two' doesn't exist.");
clean();
