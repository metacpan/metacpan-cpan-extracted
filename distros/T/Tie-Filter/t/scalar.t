# vim: set ft=perl :

use strict;

use Test::More tests => 4;
BEGIN { use_ok("Tie::Filter") };

my $scalar;

tie my $wrap, 'Tie::Filter', \$scalar,
	FETCH => sub { $_ = lc },
	STORE => sub { $_ = uc };

isa_ok(tied($wrap), 'Tie::Filter::Scalar');

$wrap = 'aBc';
is($wrap, 'abc');
is($scalar, 'ABC');
