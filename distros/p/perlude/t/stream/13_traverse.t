use strict;
use warnings;
use 5.10.0;
use Test::More;
use Perlude;

sub sum { now {state $sum = 0; $sum += $_ } shift }

my @tests =
( [ undef, sub {} ]
, [ 10 => take 10, sub {1} ]
, [ 15 => unfold 1 .. 5 ]
, [ 0  => take 10, cycle -1, 1 ]
);

plan tests => 0+ @tests;

for my $t (@tests) {
    my ( $sum, $i ) = @$t;
    is( sum($i), $sum, "sum = @{[ defined $sum ? $sum : '<undef>' ]}" );
}

