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
my $keys = keys %hash;
ok(exists $hash{'one'}, "Key 'one' exists.");
ok(exists $hash{'two'}, "Key 'two' exists.");
ok(! exists $hash{'three'}, "Key 'three' doesn't exist.");
