#!perl

use strict;
use Test::More;
use Time::Duration::id;

use constant MINUTE =>   60;
use constant HOUR   => 3600;
use constant DAY    =>   24 * HOUR;
use constant YEAR   =>  365 * DAY;

# --------------------------------------------------------------------
# Basic tests..

my @basic_tests = (
    [ duration(    0), '0 detik' ],
    [ duration(    1), '1 detik' ],
    [ duration(   -1), '1 detik' ],
    [ duration( 3602), '1 jam 2 detik' ],
    [ duration(-3602), '1 jam 2 detik' ],

    [ later(   0), 'sekarang' ],
    [ later(   2), '2 detik lagi' ],
    [ later(  -2), '2 detik lalu' ],
    [ earlier( 0), 'sekarang' ],
    [ earlier( 2), '2 detik lalu' ],
    [ earlier(-2), '2 detik lagi' ],

    [ ago(      0), 'sekarang' ],
    [ ago(      2), '2 detik lalu' ],
    [ ago(     -2), '2 detik lagi' ],
    [ from_now( 0), 'sekarang' ],
    [ from_now( 2), '2 detik lagi' ],
    [ from_now(-2), '2 detik lalu' ],
);

# --------------------------------------------------------------------
# Some tests of concise() ...

my @concise_tests = (
    [ concise duration(   0), '0d' ],
    [ concise duration(   1), '1d' ],
    [ concise duration(  -1), '1d' ],
    [ concise duration(   2), '2d' ],
    [ concise duration(  -2), '2d' ],

    [ concise later(   0), 'sekarang' ],
    [ concise later(   2), '2d lagi' ],
    [ concise later(  -2), '2d lalu' ],
    [ concise earlier( 0), 'sekarang' ],
    [ concise earlier( 2), '2d lalu' ],
    [ concise earlier(-2), '2d lagi' ],

    [ concise ago(      0), 'sekarang' ],
    [ concise ago(      2), '2d lalu' ],
    [ concise ago(     -2), '2d lagi' ],
    [ concise from_now( 0), 'sekarang' ],
    [ concise from_now( 2), '2d lagi' ],
    [ concise from_now(-2), '2d lalu' ],
);

# --------------------------------------------------------------------
# execute the test

for my $case (@basic_tests) {
    is($case->[0], $case->[1], $case->[1]);
}

for my $case (@concise_tests) {
    is($case->[0], $case->[1], $case->[1]);
}

done_testing;
