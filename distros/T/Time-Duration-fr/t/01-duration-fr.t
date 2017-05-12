#!perl -T
# Translated and converted to Test::More from Time::Duration's t/01_tdur.t
use utf8;
use strict;
use Test::More;
use Time::Duration::fr;

use constant MINUTE =>   60;
use constant HOUR   => 3600;
use constant DAY    =>   24 * HOUR;
use constant YEAR   =>  365 * DAY;

# --------------------------------------------------------------------
# Basic tests..

my @basic_tests = (
    [ duration(   0), '0 seconde' ],
    [ duration(   1), '1 seconde' ],
    [ duration(  -1), '1 seconde' ],
    [ duration(   2), '2 secondes' ],
    [ duration(  -2), '2 secondes' ],

    [ later(   0), 'maintenant' ],
    [ later(   2), '2 secondes plus tard' ],
    [ later(  -2), '2 secondes plus tôt' ],
    [ earlier( 0), 'maintenant' ],
    [ earlier( 2), '2 secondes plus tôt' ],
    [ earlier(-2), '2 secondes plus tard' ],

    [ ago(      0), 'maintenant' ],
    [ ago(      2), 'il y a 2 secondes' ],
    [ ago(     -2), 'dans 2 secondes' ],
    [ from_now( 0), 'maintenant' ],
    [ from_now( 2), 'dans 2 secondes' ],
    [ from_now(-2), 'il y a 2 secondes' ],
);

# --------------------------------------------------------------------
# Advanced tests...

my $v;  #scratch var
my @advanced_tests;

$v = 0;
@advanced_tests = (
    [ later(       $v   ), 'maintenant' ],
    [ later(       $v, 3), 'maintenant' ],
    [ later_exact( $v   ), 'maintenant' ],
);

$v = 1;
push @advanced_tests,
    [ later(       $v   ), '1 seconde plus tard' ],
    [ later(       $v, 3), '1 seconde plus tard' ],
    [ later_exact( $v   ), '1 seconde plus tard' ];

$v = 30;
push @advanced_tests,
    [ later(       $v   ), '30 secondes plus tard' ],
    [ later(       $v, 3), '30 secondes plus tard' ],
    [ later_exact( $v   ), '30 secondes plus tard' ];

$v = 46;
push @advanced_tests,
    [ later(       $v   ), '46 secondes plus tard' ],
    [ later(       $v, 3), '46 secondes plus tard' ],
    [ later_exact( $v   ), '46 secondes plus tard' ];

$v = 59;
push @advanced_tests,
    [ later(       $v   ), '59 secondes plus tard' ],
    [ later(       $v, 3), '59 secondes plus tard' ],
    [ later_exact( $v   ), '59 secondes plus tard' ];

$v = 61;
push @advanced_tests,
    [ later(       $v   ), '1 minute et 1 seconde plus tard' ],
    [ later(       $v, 3), '1 minute et 1 seconde plus tard' ],
    [ later_exact( $v   ), '1 minute et 1 seconde plus tard' ];

$v = 3599;
push @advanced_tests,
    [ later(       $v   ), '59 minutes et 59 secondes plus tard' ],
    [ later(       $v, 3), '59 minutes et 59 secondes plus tard' ],
    [ later_exact( $v   ), '59 minutes et 59 secondes plus tard' ];

$v = 3600;
push @advanced_tests,
    [ later(       $v   ), '1 heure plus tard' ],
    [ later(       $v, 3), '1 heure plus tard' ],
    [ later_exact( $v   ), '1 heure plus tard' ];

$v = 3601;
push @advanced_tests,
    [ later(       $v   ), '1 heure et 1 seconde plus tard' ],
    [ later(       $v, 3), '1 heure et 1 seconde plus tard' ],
    [ later_exact( $v   ), '1 heure et 1 seconde plus tard' ];

$v = 3630;
push @advanced_tests,
    [ later(       $v   ), '1 heure et 30 secondes plus tard' ],
    [ later(       $v, 3), '1 heure et 30 secondes plus tard' ],
    [ later_exact( $v   ), '1 heure et 30 secondes plus tard' ];

$v = 3800;
push @advanced_tests,
    [ later(       $v   ), '1 heure et 3 minutes plus tard' ],
    [ later(       $v, 3), '1 heure, 3 minutes, et 20 secondes plus tard' ],
    [ later_exact( $v   ), '1 heure, 3 minutes, et 20 secondes plus tard' ];

$v = 3820;
push @advanced_tests,
    [ later(       $v   ), '1 heure et 4 minutes plus tard' ],
    [ later(       $v, 3), '1 heure, 3 minutes, et 40 secondes plus tard' ],
    [ later_exact( $v   ), '1 heure, 3 minutes, et 40 secondes plus tard' ];

$v = DAY + - HOUR + -28;
push @advanced_tests,
    [ later(       $v   ), '23 heures plus tard' ],
    [ later(       $v, 3), '22 heures, 59 minutes, et 32 secondes plus tard' ],
    [ later_exact( $v   ), '22 heures, 59 minutes, et 32 secondes plus tard' ];

$v = DAY + - HOUR + MINUTE;
push @advanced_tests,
    [ later(       $v   ), '23 heures et 1 minute plus tard' ],
    [ later(       $v, 3), '23 heures et 1 minute plus tard' ],
    [ later_exact( $v   ), '23 heures et 1 minute plus tard' ];

$v = DAY + - HOUR + 29 * MINUTE + 1;
push @advanced_tests,
    [ later(       $v   ), '23 heures et 29 minutes plus tard' ],
    [ later(       $v, 3), '23 heures, 29 minutes, et 1 seconde plus tard' ],
    [ later_exact( $v   ), '23 heures, 29 minutes, et 1 seconde plus tard' ];

$v = DAY + - HOUR + 29 * MINUTE + 31;
push @advanced_tests,
    [ later(       $v   ), '23 heures et 30 minutes plus tard' ],
    [ later(       $v, 3), '23 heures, 29 minutes, et 31 secondes plus tard' ],
    [ later_exact( $v   ), '23 heures, 29 minutes, et 31 secondes plus tard' ];

$v = DAY + - HOUR + 30 * MINUTE + 31;
push @advanced_tests,
    [ later(       $v   ), '23 heures et 31 minutes plus tard' ],
    [ later(       $v, 3), '23 heures, 30 minutes, et 31 secondes plus tard' ],
    [ later_exact( $v   ), '23 heures, 30 minutes, et 31 secondes plus tard' ];

$v = DAY + - HOUR + -28 + YEAR;
push @advanced_tests,
    [ later(       $v   ), '1 année et 23 heures plus tard' ],
    [ later(       $v, 3), '1 année et 23 heures plus tard' ],
    [ later_exact( $v   ), '1 année, 22 heures, 59 minutes, et 32 secondes plus tard' ];

$v = DAY + - HOUR + MINUTE + YEAR;
push @advanced_tests,
    [ later(       $v   ), '1 année et 23 heures plus tard' ],
    [ later(       $v, 3), '1 année, 23 heures, et 1 minute plus tard' ],
    [ later_exact( $v   ), '1 année, 23 heures, et 1 minute plus tard' ];

$v = DAY + - HOUR + 29 * MINUTE + 1 + YEAR;
push @advanced_tests,
    [ later(       $v   ), '1 année et 23 heures plus tard' ],
    [ later(       $v, 3), '1 année, 23 heures, et 29 minutes plus tard' ],
    [ later_exact( $v   ), '1 année, 23 heures, 29 minutes, et 1 seconde plus tard' ];

$v = DAY + - HOUR + 29 * MINUTE + 31 + YEAR;
push @advanced_tests,
    [ later(       $v   ), '1 année et 23 heures plus tard' ],
    [ later(       $v, 3), '1 année, 23 heures, et 30 minutes plus tard' ],
    [ later_exact( $v   ), '1 année, 23 heures, 29 minutes, et 31 secondes plus tard' ];

$v = YEAR + 2 * HOUR + -1;
push @advanced_tests,
    [ later(       $v   ), '1 année et 2 heures plus tard' ],
    [ later(       $v, 3), '1 année et 2 heures plus tard' ],
    [ later_exact( $v   ), '1 année, 1 heure, 59 minutes, et 59 secondes plus tard' ];

$v = YEAR + 2 * HOUR + 59;
push @advanced_tests,
    [ later(       $v   ), '1 année et 2 heures plus tard' ],
    [ later(       $v, 3), '1 année, 2 heures, et 59 secondes plus tard' ],
    [ later_exact( $v   ), '1 année, 2 heures, et 59 secondes plus tard' ];

$v = YEAR + DAY + 2 * HOUR + -1;
push @advanced_tests,
    [ later(       $v   ), '1 année et 1 jour plus tard' ],
    [ later(       $v, 3), '1 année, 1 jour, et 2 heures plus tard' ],
    [ later_exact( $v   ), '1 année, 1 jour, 1 heure, 59 minutes, et 59 secondes plus tard' ];

$v = YEAR + DAY + 2 * HOUR + 59;
push @advanced_tests,
    [ later(       $v   ), '1 année et 1 jour plus tard' ],
    [ later(       $v, 3), '1 année, 1 jour, et 2 heures plus tard' ],
    [ later_exact( $v   ), '1 année, 1 jour, 2 heures, et 59 secondes plus tard' ];

$v = YEAR + - DAY + - 1;
push @advanced_tests,
    [ later(       $v   ), '364 jours plus tard' ],
    [ later(       $v, 3), '364 jours plus tard' ],
    [ later_exact( $v   ), '363 jours, 23 heures, 59 minutes, et 59 secondes plus tard' ];

$v = YEAR + - 1;
push @advanced_tests,
    [ later(       $v   ), '1 année plus tard' ],
    [ later(       $v, 3), '1 année plus tard' ],
    [ later_exact( $v   ), '364 jours, 23 heures, 59 minutes, et 59 secondes plus tard' ];


# And an advanced one to put duration thru its paces...

$v = YEAR + DAY + 2 * HOUR + 59;
my @more_advanced_tests = (
    [ duration(       $v   ), '1 année et 1 jour' ],
    [ duration(       $v, 3), '1 année, 1 jour, et 2 heures' ],
    [ duration_exact( $v   ), '1 année, 1 jour, 2 heures, et 59 secondes' ],
    [ duration(      -$v   ), '1 année et 1 jour' ],
    [ duration(      -$v, 3), '1 année, 1 jour, et 2 heures' ],
    [ duration_exact(-$v   ), '1 année, 1 jour, 2 heures, et 59 secondes' ],
);


# --------------------------------------------------------------------
# Some tests of concise() ...

my @concise_tests = (
    [ concise duration(   0), '0s' ],
    [ concise duration(   1), '1s' ],
    [ concise duration(  -1), '1s' ],
    [ concise duration(   2), '2s' ],
    [ concise duration(  -2), '2s' ],
  
    [ concise later(   0), 'maintenant' ],
    [ concise later(   2), '2s plus tard' ],
    [ concise later(  -2), '2s plus tôt' ],
    [ concise earlier( 0), 'maintenant' ],
    [ concise earlier( 2), '2s plus tôt' ],
    [ concise earlier(-2), '2s plus tard' ],
  
    [ concise ago(      0), 'maintenant' ],
    [ concise ago(      2), 'il y a 2s' ],
    [ concise ago(     -2), 'dans 2s' ],
    [ concise from_now( 0), 'maintenant' ],
    [ concise from_now( 2), 'dans 2s' ],
    [ concise from_now(-2), 'il y a 2s' ],
);

$v = YEAR + DAY + 2 * HOUR + -1;
push @concise_tests,
    [ concise later(       $v   ), '1a1j plus tard' ],
    [ concise later(       $v, 3), '1a1j2h plus tard' ],
    [ concise later_exact( $v   ), '1a1j1h59m59s plus tard' ];

$v = YEAR + DAY + 2 * HOUR + 59;
push @concise_tests,
    [ concise later(       $v   ), '1a1j plus tard' ],
    [ concise later(       $v, 3), '1a1j2h plus tard' ],
    [ concise later_exact( $v   ), '1a1j2h59s plus tard' ];

$v = YEAR + - DAY + - 1;
push @concise_tests,
    [ concise later(       $v   ), '364j plus tard' ],
    [ concise later(       $v, 3), '364j plus tard' ],
    [ concise later_exact( $v   ), '363j23h59m59s plus tard' ];

$v = YEAR + - 1;
push @concise_tests,
    [ concise later(       $v   ), '1a plus tard' ],
    [ concise later(       $v, 3), '1a plus tard' ],
    [ concise later_exact( $v   ), '364j23h59m59s plus tard' ];


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

