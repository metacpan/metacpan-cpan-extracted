# vim: set ft=perl :

use strict;

use Test::More tests => 14;
BEGIN { use_ok("Tie::Filter") };

my @array;

tie my @wrap, 'Tie::Filter', \@array,
	FETCH => sub { $_ = lc },
	STORE => sub { $_ = uc };

isa_ok(tied(@wrap), 'Tie::Filter::Array');

$wrap[0] = 'aBc';
$wrap[1] = 'def';
$wrap[2] = 'GHi';

is($wrap[0], 'abc');
is($wrap[1], 'def');
is($wrap[2], 'ghi');

is($array[0], 'ABC');
is($array[1], 'DEF');
is($array[2], 'GHI');

ok(exists $wrap[1]);

ok(defined delete $wrap[2]);
ok(!exists $array[2]);

is_deeply(\@wrap,  [ qw(abc def) ]);
is_deeply(\@array, [ qw(ABC DEF) ]);

@wrap = ();
is_deeply(\@array, []);
