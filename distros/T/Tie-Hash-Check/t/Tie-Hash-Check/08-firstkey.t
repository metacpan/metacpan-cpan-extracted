# Pragmas.
use strict;
use warnings;

# Modules.
use Tie::Hash::Check;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
tie my %hash, 'Tie::Hash::Check', {
	'one' => 1,
	'two' => 2,
};
my ($key) = sort keys %hash;
is($key, 'one', 'Get first key.');
