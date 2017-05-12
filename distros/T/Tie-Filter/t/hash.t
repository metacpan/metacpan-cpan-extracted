# vim: set ft=perl :

use strict;

use Test::More tests => 16;
BEGIN { use_ok("Tie::Filter") };

my %hash;

tie my %wrap, 'Tie::Filter', \%hash,
	FETCHKEY   => sub { $_ = lc },
	STOREKEY   => sub { $_ = uc },
	FETCHVALUE => sub { $_ = uc },
	STOREVALUE => sub { $_ = lc };

isa_ok(tied(%wrap), 'Tie::Filter::Hash');

$wrap{aBc} = 'zyX';
$wrap{def} = 'WVu';
$wrap{GHi} = 'TSR';

is($wrap{abc}, 'ZYX');
is($wrap{dEF}, 'WVU');
is($wrap{gHI}, 'TSR');

is($hash{ABC}, 'zyx');
is($hash{DEF}, 'wvu');
is($hash{GHI}, 'tsr');

ok(exists $wrap{DeF});

ok(defined delete $wrap{gHi});
ok(!exists $hash{GHI});

my @keys   = sort keys %wrap;
my @values = sort values %wrap;
is_deeply(\@keys, [ qw(abc def) ]);
is_deeply(\@values, [ qw(WVU ZYX) ]);

@keys   = sort keys %hash;
@values = sort values %hash;
is_deeply(\@keys, [ qw(ABC DEF) ]);
is_deeply(\@values, [ qw(wvu zyx) ]);

%wrap = ();
is_deeply(\%hash, {});
