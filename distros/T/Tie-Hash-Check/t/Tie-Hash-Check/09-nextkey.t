# Pragmas.
use strict;
use warnings;

# Modules.
use Tie::Hash::Check;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
tie my %hash, 'Tie::Hash::Check', {
	'one' => 1,
	'two' => 2,
};
my $num = 0;
while (my ($key, $val) = each %hash) {
	if ($key eq 'one') {
		is($val, '1', "Get value for 'one' key.");
	} else {
		is($key, 'two', "Get 'two' key.");
		is($val, 2, "Get value for 'two' key.");
	}
}
