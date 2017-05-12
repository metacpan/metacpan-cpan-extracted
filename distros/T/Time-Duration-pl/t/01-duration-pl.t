#!perl

use utf8;
use strict;
use Test::More;
use Time::Duration::pl;

use constant MINUTE =>   60;
use constant HOUR   => 3600;
use constant DAY    =>   24 * HOUR;
use constant YEAR   =>  365 * DAY;

my $builder = Test::More->builder;
binmode $builder->output,         ':utf8';
binmode $builder->failure_output, ':utf8';
binmode $builder->todo_output,    ':utf8';

# --------------------------------------------------------------------
# Basic tests...

my @basic_tests = (
    [ duration(   0), '0 sekund' ],
    [ duration(   1), '1 sekunda' ],
    [ duration(  -1), '1 sekunda' ],
    [ duration(   2), '2 sekundy' ],
    [ duration(  -2), '2 sekundy' ],

    [ later(   0), 'teraz' ],
    [ later(   2), '2 sekundy później' ],
    [ later(  -2), '2 sekundy wcześniej' ],
    [ earlier( 0), 'teraz' ],
    [ earlier( 2), '2 sekundy wcześniej' ],
    [ earlier(-2), '2 sekundy później' ],

    [ ago(      0), 'teraz' ],
    [ ago(      2), '2 sekundy temu' ],
    [ ago(     -2), 'za 2 sekundy' ],
    [ from_now( 0), 'teraz' ],
    [ from_now( 2), 'za 2 sekundy' ],
    [ from_now(-2), '2 sekundy temu' ],
);

# --------------------------------------------------------------------
# Advanced tests...

my $v;  #scratch var
my @advanced_tests;

$v = 0;
@advanced_tests = (
    [ later(       $v   ), 'teraz' ],
    [ later(       $v, 3), 'teraz' ],
    [ later_exact( $v   ), 'teraz' ],
);

$v = 1;
push @advanced_tests,
    [ later(       $v   ), '1 sekunda później' ],
    [ later(       $v, 3), '1 sekunda później' ],
    [ later_exact( $v   ), '1 sekunda później' ];

$v = 2;
push @advanced_tests,
    [ later(       $v   ), '2 sekundy później' ],
    [ later(       $v, 3), '2 sekundy później' ],
    [ later_exact( $v   ), '2 sekundy później' ];

$v = 3;
push @advanced_tests,
    [ later(       $v   ), '3 sekundy później' ],
    [ later(       $v, 3), '3 sekundy później' ],
    [ later_exact( $v   ), '3 sekundy później' ];

$v = 4;
push @advanced_tests,
    [ later(       $v   ), '4 sekundy później' ],
    [ later(       $v, 3), '4 sekundy później' ],
    [ later_exact( $v   ), '4 sekundy później' ];

$v = 5;
push @advanced_tests,
    [ later(       $v   ), '5 sekund później' ],
    [ later(       $v, 3), '5 sekund później' ],
    [ later_exact( $v   ), '5 sekund później' ];

$v = 6;
push @advanced_tests,
    [ later(       $v   ), '6 sekund później' ],
    [ later(       $v, 3), '6 sekund później' ],
    [ later_exact( $v   ), '6 sekund później' ];

$v = 7;
push @advanced_tests,
    [ later(       $v   ), '7 sekund później' ],
    [ later(       $v, 3), '7 sekund później' ],
    [ later_exact( $v   ), '7 sekund później' ];

$v = 8;
push @advanced_tests,
    [ later(       $v   ), '8 sekund później' ],
    [ later(       $v, 3), '8 sekund później' ],
    [ later_exact( $v   ), '8 sekund później' ];
$v = 9;
push @advanced_tests,
    [ later(       $v   ), '9 sekund później' ],
    [ later(       $v, 3), '9 sekund później' ],
    [ later_exact( $v   ), '9 sekund później' ];

$v = 10;
push @advanced_tests,
    [ later(       $v   ), '10 sekund później' ],
    [ later(       $v, 3), '10 sekund później' ],
    [ later_exact( $v   ), '10 sekund później' ];

$v = 11;
push @advanced_tests,
    [ later(       $v   ), '11 sekund później' ],
    [ later(       $v, 3), '11 sekund później' ],
    [ later_exact( $v   ), '11 sekund później' ];

$v = 12;
push @advanced_tests,
    [ later(       $v   ), '12 sekund później' ],
    [ later(       $v, 3), '12 sekund później' ],
    [ later_exact( $v   ), '12 sekund później' ];

$v = 13;
push @advanced_tests,
    [ later(       $v   ), '13 sekund później' ],
    [ later(       $v, 3), '13 sekund później' ],
    [ later_exact( $v   ), '13 sekund później' ];

$v = 14;
push @advanced_tests,
    [ later(       $v   ), '14 sekund później' ],
    [ later(       $v, 3), '14 sekund później' ],
    [ later_exact( $v   ), '14 sekund później' ];

$v = 15;
push @advanced_tests,
    [ later(       $v   ), '15 sekund później' ],
    [ later(       $v, 3), '15 sekund później' ],
    [ later_exact( $v   ), '15 sekund później' ];

$v = 16;
push @advanced_tests,
    [ later(       $v   ), '16 sekund później' ],
    [ later(       $v, 3), '16 sekund później' ],
    [ later_exact( $v   ), '16 sekund później' ];

$v = 17;
push @advanced_tests,
    [ later(       $v   ), '17 sekund później' ],
    [ later(       $v, 3), '17 sekund później' ],
    [ later_exact( $v   ), '17 sekund później' ];

$v = 18;
push @advanced_tests,
    [ later(       $v   ), '18 sekund później' ],
    [ later(       $v, 3), '18 sekund później' ],
    [ later_exact( $v   ), '18 sekund później' ];

$v = 19;
push @advanced_tests,
    [ later(       $v   ), '19 sekund później' ],
    [ later(       $v, 3), '19 sekund później' ],
    [ later_exact( $v   ), '19 sekund później' ];

$v = 20;
push @advanced_tests,
    [ later(       $v   ), '20 sekund później' ],
    [ later(       $v, 3), '20 sekund później' ],
    [ later_exact( $v   ), '20 sekund później' ];

$v = 21;
push @advanced_tests,
    [ later(       $v   ), '21 sekund później' ],
    [ later(       $v, 3), '21 sekund później' ],
    [ later_exact( $v   ), '21 sekund później' ];

$v = 22;
push @advanced_tests,
    [ later(       $v   ), '22 sekundy później' ],
    [ later(       $v, 3), '22 sekundy później' ],
    [ later_exact( $v   ), '22 sekundy później' ];

$v = 23;
push @advanced_tests,
    [ later(       $v   ), '23 sekundy później' ],
    [ later(       $v, 3), '23 sekundy później' ],
    [ later_exact( $v   ), '23 sekundy później' ];

$v = 24;
push @advanced_tests,
    [ later(       $v   ), '24 sekundy później' ],
    [ later(       $v, 3), '24 sekundy później' ],
    [ later_exact( $v   ), '24 sekundy później' ];

$v = 25;
push @advanced_tests,
    [ later(       $v   ), '25 sekund później' ],
    [ later(       $v, 3), '25 sekund później' ],
    [ later_exact( $v   ), '25 sekund później' ];

$v = 26;
push @advanced_tests,
    [ later(       $v   ), '26 sekund później' ],
    [ later(       $v, 3), '26 sekund później' ],
    [ later_exact( $v   ), '26 sekund później' ];

$v = 27;
push @advanced_tests,
    [ later(       $v   ), '27 sekund później' ],
    [ later(       $v, 3), '27 sekund później' ],
    [ later_exact( $v   ), '27 sekund później' ];

$v = 28;
push @advanced_tests,
    [ later(       $v   ), '28 sekund później' ],
    [ later(       $v, 3), '28 sekund później' ],
    [ later_exact( $v   ), '28 sekund później' ];

$v = 29;
push @advanced_tests,
    [ later(       $v   ), '29 sekund później' ],
    [ later(       $v, 3), '29 sekund później' ],
    [ later_exact( $v   ), '29 sekund później' ];

$v = 30;
push @advanced_tests,
    [ later(       $v   ), '30 sekund później' ],
    [ later(       $v, 3), '30 sekund później' ],
    [ later_exact( $v   ), '30 sekund później' ];

$v = 46;
push @advanced_tests,
    [ later(       $v   ), '46 sekund później' ],
    [ later(       $v, 3), '46 sekund później' ],
    [ later_exact( $v   ), '46 sekund później' ];

$v = 59;
push @advanced_tests,
    [ later(       $v   ), '59 sekund później' ],
    [ later(       $v, 3), '59 sekund później' ],
    [ later_exact( $v   ), '59 sekund później' ];

$v = 61;
push @advanced_tests,
    [ later(       $v   ), '1 minuta i 1 sekunda później' ],
    [ later(       $v, 3), '1 minuta i 1 sekunda później' ],
    [ later_exact( $v   ), '1 minuta i 1 sekunda później' ];

$v = 3599;
push @advanced_tests,
    [ later(       $v   ), '59 minut i 59 sekund później' ],
    [ later(       $v, 3), '59 minut i 59 sekund później' ],
    [ later_exact( $v   ), '59 minut i 59 sekund później' ];

$v = 3600;
push @advanced_tests,
    [ later(       $v   ), '1 godzina później' ],
    [ later(       $v, 3), '1 godzina później' ],
    [ later_exact( $v   ), '1 godzina później' ];

$v = 3601;
push @advanced_tests,
    [ later(       $v   ), '1 godzina i 1 sekunda później' ],
    [ later(       $v, 3), '1 godzina i 1 sekunda później' ],
    [ later_exact( $v   ), '1 godzina i 1 sekunda później' ];

$v = 3630;
push @advanced_tests,
    [ later(       $v   ), '1 godzina i 30 sekund później' ],
    [ later(       $v, 3), '1 godzina i 30 sekund później' ],
    [ later_exact( $v   ), '1 godzina i 30 sekund później' ];

$v = 3800;
push @advanced_tests,
    [ later(       $v   ), '1 godzina i 3 minuty później' ],
    [ later(       $v, 3), '1 godzina, 3 minuty i 20 sekund później' ],
    [ later_exact( $v   ), '1 godzina, 3 minuty i 20 sekund później' ];

$v = 3820;
push @advanced_tests,
    [ later(       $v   ), '1 godzina i 4 minuty później' ],
    [ later(       $v, 3), '1 godzina, 3 minuty i 40 sekund później' ],
    [ later_exact( $v   ), '1 godzina, 3 minuty i 40 sekund później' ];

$v = DAY + - HOUR + -28;
push @advanced_tests,
    [ later(       $v   ), '23 godziny później' ],
    [ later(       $v, 3), '22 godziny, 59 minut i 32 sekundy później' ],
    [ later_exact( $v   ), '22 godziny, 59 minut i 32 sekundy później' ];

$v = DAY + - HOUR + MINUTE;
push @advanced_tests,
    [ later(       $v   ), '23 godziny i 1 minuta później' ],
    [ later(       $v, 3), '23 godziny i 1 minuta później' ],
    [ later_exact( $v   ), '23 godziny i 1 minuta później' ];

$v = DAY + - HOUR + 29 * MINUTE + 1;
push @advanced_tests,
    [ later(       $v   ), '23 godziny i 29 minut później' ],
    [ later(       $v, 3), '23 godziny, 29 minut i 1 sekunda później' ],
    [ later_exact( $v   ), '23 godziny, 29 minut i 1 sekunda później' ];

$v = DAY + - HOUR + 29 * MINUTE + 31;
push @advanced_tests,
    [ later(       $v   ), '23 godziny i 30 minut później' ],
    [ later(       $v, 3), '23 godziny, 29 minut i 31 sekund później' ],
    [ later_exact( $v   ), '23 godziny, 29 minut i 31 sekund później' ];

$v = DAY + - HOUR + 30 * MINUTE + 31;
push @advanced_tests,
    [ later(       $v   ), '23 godziny i 31 minut później' ],
    [ later(       $v, 3), '23 godziny, 30 minut i 31 sekund później' ],
    [ later_exact( $v   ), '23 godziny, 30 minut i 31 sekund później' ];

$v = DAY + - HOUR + -28 + YEAR;
push @advanced_tests,
    [ later(       $v   ), '1 rok i 23 godziny później' ],
    [ later(       $v, 3), '1 rok i 23 godziny później' ],
    [ later_exact( $v   ), '1 rok, 22 godziny, 59 minut i 32 sekundy później' ];

$v = DAY + - HOUR + MINUTE + YEAR;
push @advanced_tests,
    [ later(       $v   ), '1 rok i 23 godziny później' ],
    [ later(       $v, 3), '1 rok, 23 godziny i 1 minuta później' ],
    [ later_exact( $v   ), '1 rok, 23 godziny i 1 minuta później' ];

$v = DAY + - HOUR + 29 * MINUTE + 1 + YEAR;
push @advanced_tests,
    [ later(       $v   ), '1 rok i 23 godziny później' ],
    [ later(       $v, 3), '1 rok, 23 godziny i 29 minut później' ],
    [ later_exact( $v   ), '1 rok, 23 godziny, 29 minut i 1 sekunda później' ];

$v = DAY + - HOUR + 29 * MINUTE + 31 + YEAR;
push @advanced_tests,
    [ later(       $v   ), '1 rok i 23 godziny później' ],
    [ later(       $v, 3), '1 rok, 23 godziny i 30 minut później' ],
    [ later_exact( $v   ), '1 rok, 23 godziny, 29 minut i 31 sekund później' ];

$v = YEAR + 2 * HOUR + -1;
push @advanced_tests,
    [ later(       $v   ), '1 rok i 2 godziny później' ],
    [ later(       $v, 3), '1 rok i 2 godziny później' ],
    [ later_exact( $v   ), '1 rok, 1 godzina, 59 minut i 59 sekund później' ];

$v = YEAR + 2 * HOUR + 59;
push @advanced_tests,
    [ later(       $v   ), '1 rok i 2 godziny później' ],
    [ later(       $v, 3), '1 rok, 2 godziny i 59 sekund później' ],
    [ later_exact( $v   ), '1 rok, 2 godziny i 59 sekund później' ];

$v = YEAR + DAY + 2 * HOUR + -1;
push @advanced_tests,
    [ later(       $v   ), '1 rok i 1 dzień później' ],
    [ later(       $v, 3), '1 rok, 1 dzień i 2 godziny później' ],
    [ later_exact( $v   ), '1 rok, 1 dzień, 1 godzina, 59 minut i 59 sekund później' ];

$v = YEAR + DAY + 2 * HOUR + 59;
push @advanced_tests,
    [ later(       $v   ), '1 rok i 1 dzień później' ],
    [ later(       $v, 3), '1 rok, 1 dzień i 2 godziny później' ],
    [ later_exact( $v   ), '1 rok, 1 dzień, 2 godziny i 59 sekund później' ];

$v = YEAR + - DAY + - 1;
push @advanced_tests,
    [ later(       $v   ), '364 dni później' ],
    [ later(       $v, 3), '364 dni później' ],
    [ later_exact( $v   ), '363 dni, 23 godziny, 59 minut i 59 sekund później' ];

$v = YEAR + - 1;
push @advanced_tests,
    [ later(       $v   ), '1 rok później' ],
    [ later(       $v, 3), '1 rok później' ],
    [ later_exact( $v   ), '364 dni, 23 godziny, 59 minut i 59 sekund później' ];

# And an advanced one to put duration thru its paces...

$v = YEAR + DAY + 2 * HOUR + 59;
my @more_advanced_tests = (
    [ duration(       $v   ), '1 rok i 1 dzień' ],
    [ duration(       $v, 3), '1 rok, 1 dzień i 2 godziny' ],
    [ duration_exact( $v   ), '1 rok, 1 dzień, 2 godziny i 59 sekund' ],
    [ duration(      -$v   ), '1 rok i 1 dzień' ],
    [ duration(      -$v, 3), '1 rok, 1 dzień i 2 godziny' ],
    [ duration_exact(-$v   ), '1 rok, 1 dzień, 2 godziny i 59 sekund' ],
);

$v = 3 * YEAR + 14 * DAY + 5 * HOUR + 52;
push @more_advanced_tests,
    [ duration(       $v   ), '3 lata i 14 dni' ],
    [ duration(       $v, 3), '3 lata, 14 dni i 5 godzin' ],
    [ duration_exact( $v   ), '3 lata, 14 dni, 5 godzin i 52 sekundy' ],
    [ duration(      -$v   ), '3 lata i 14 dni' ],
    [ duration(      -$v, 3), '3 lata, 14 dni i 5 godzin' ],
    [ duration_exact(-$v   ), '3 lata, 14 dni, 5 godzin i 52 sekundy' ];

# --------------------------------------------------------------------
# Some tests of concise...

my @concise_tests = (
    [ concise duration(   0), '0s' ],
    [ concise duration(   1), '1s' ],
    [ concise duration(  -1), '1s' ],
    [ concise duration(   2), '2s' ],
    [ concise duration(  -2), '2s' ],

    [ concise later(   0), 'teraz' ],
    [ concise later(   2), '2s później' ],
    [ concise later(  -2), '2s wcześniej' ],
    [ concise earlier( 0), 'teraz' ],
    [ concise earlier( 2), '2s wcześniej' ],
    [ concise earlier(-2), '2s później' ],

    [ concise ago(      0), 'teraz' ],
    [ concise ago(      2), '2s temu' ],
    [ concise ago(     -2), 'za 2s' ],
    [ concise from_now( 0), 'teraz' ],
    [ concise from_now( 2), 'za 2s' ],
    [ concise from_now(-2), '2s temu' ],
);

$v = YEAR + DAY + 2 * HOUR + -1;
push @concise_tests,
    [ concise later(       $v   ), '1r1d później' ],
    [ concise later(       $v, 3), '1r1d2g później' ],
    [ concise later_exact( $v   ), '1r1d1g59m59s później' ];

$v = YEAR + DAY + 2 * HOUR + 59;
push @concise_tests,
    [ concise later(       $v   ), '1r1d później' ],
    [ concise later(       $v, 3), '1r1d2g później' ],
    [ concise later_exact( $v   ), '1r1d2g59s później' ];

$v = YEAR + - DAY + - 1;
push @concise_tests,
    [ concise later(       $v   ), '364d później' ],
    [ concise later(       $v, 3), '364d później' ],
    [ concise later_exact( $v   ), '363d23g59m59s później' ];

$v = YEAR + - 1;
push @concise_tests,
    [ concise later(       $v   ), '1r później' ],
    [ concise later(       $v, 3), '1r później' ],
    [ concise later_exact( $v   ), '364d23g59m59s później' ];

# --------------------------------------------------------------------
# execute the test
plan tests => @basic_tests + @advanced_tests + @more_advanced_tests
            + @concise_tests;

for my $case (@basic_tests) {
    is($case->[0], $case->[1], $case->[1]);
}

for my $case (@advanced_tests) {
    is($case->[0], $case->[1], $case->[1]);
}

for my $case (@more_advanced_tests) {
    is($case->[0], $case->[1], $case->[1]);
}

for my $case (@concise_tests) {
    is($case->[0], $case->[1], $case->[1]);
}
