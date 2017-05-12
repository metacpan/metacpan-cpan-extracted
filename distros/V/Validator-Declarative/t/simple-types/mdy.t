#!/usr/bin/env perl

use strict;
use warnings;

use Test::Validator::Declarative qw/ check_type_validation /;

my $year  = [ 1 .. 99, 1970, 1999 .. 2015, 3000 ];
my $month = [ 1 .. 12 ];
my $day   = [ 1 .. 31 ];
check_type_validation(
    type => 'mdy',
    good => [
        map {
            my $d = $_;
            map {
                my $m = $_;
                map {
                    my $y = $_;
                    $y < 100
                        ? sprintf( '%02d/%02d/%02d', $m, $d, $y )
                        : sprintf( '%02d/%02d/%04d', $m, $d, $y );
                    } @$year
                } @$month
        } @$day
    ],
    bad => [
        ( map { ( "$_$_-$_$_-$_$_$_$_", "$_$_/$_$_/$_$_$_$_" ) } ( 0 .. 9 ) ),
        '00-00-1970',
        '01-01-3001',
        '',               # empty string
        'some string',    # arbitrary string
        v5.10.2,          # v-string
        sub { return 'TRUE' },    # coderef
        0, '1.00', '0.1', '-1.00', '-0.1', -1, -10, -123.456e10,
    ]
);

