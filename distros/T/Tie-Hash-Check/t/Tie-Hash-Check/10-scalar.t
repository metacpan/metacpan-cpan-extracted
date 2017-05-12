# Pragmas.
use strict;
use warnings;

# Modules.
use English;
use Tie::Hash::Check;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
tie my %hash, 'Tie::Hash::Check', {
	'one' => 1,
	'two' => 2,
};
my $scalar = scalar %hash;
if ($PERL_VERSION lt v5.25.3) {
	like($scalar, qr{\d/8}, 'Get scalar value of hash.');
} else {
	# On Perl gt v5.25.3 `scalar %hash` returns number of pairs.
	is($scalar, 2, 'Get scalar value of hash.');
}
