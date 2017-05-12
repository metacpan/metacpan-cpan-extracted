use Test::More;

use Test::Differences;

## This mind-bender submitted by Yves Orton <demerphq@hotmail.com>
my ( $ar, $x, $y );
$ar->[0] = \$ar->[1];
$ar->[1] = \$ar->[0];
$x       = \$y;
$y       = \$x;

my @tests = (
    sub { eq_or_diff [ \"a", \"b" ], [ \"a", \"b" ] },
    sub { eq_or_diff $ar, [ $x, $y ] },
);

plan tests => scalar @tests;

$_->() for @tests;
