#!./perl

use Test::More tests => 10;
use Config;
use optimize;
use strict;
my $x :optimize(int) = 4.5;
my $y :optimize(int) = 5.6;
my $z :optimize(int);

#my($x,$y,$z) = (4.5, 5.6, 0);

$z = $x + $y;
is($z, 9, "plus");

$z = $x - $y;
is($z, -1, "minus");

$z = $x * $y;
is($z, 20, "times");

$z = $x / $y;
is($z, 0, "divide");

$z = $x / $y;
is($z, 0, "modulo");

is($x, 4.5, "scalar still floating point");

isnt(sqrt($x), 2, "functions still floating point");

isnt($x ** .5, 2, "power still floating point");

is(++$x, 5.5, "++ still floating point");

SKIP: 
if (0) {
    my $ivsize = $Config{ivsize};
    skip "ivsize == $ivsize", 2 unless $ivsize == 4 || $ivsize == 8;

    if ($ivsize == 4) {
	$z = 2**31 - 1;
	is($z + 1, -2147483648, "left shift");
    } elsif ($ivsize == 8) {
	$z = 2**63 - 1;
        my $i = $z + 1;
	ok("$i" =~ /-922337203685477580[6-9]$/, "left shift");
    }
}
$z = 0;
is(~$z, -1, "signed instead of unsigned");
