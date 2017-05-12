#!perl
use strict;
use warnings qw(all);

use Test::More;

use Text::Roman qw(roman2int int2roman milhar2int);

my @x = qw[v iii xi iv];

roman2int() for @x;
is_deeply(\@x, [qw[5 3 11 4]], q(roman2int));

int2roman() for @x;
is_deeply(\@x, [qw[V III XI IV]], q(roman2int));

my @y = qw[L_X_XXIII IV_VIII];
milhar2int() for @y;
is_deeply(\@y, [60023, 4008], q(milhar2int));

done_testing 3;
