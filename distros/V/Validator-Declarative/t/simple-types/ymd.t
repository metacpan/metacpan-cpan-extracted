#!/usr/bin/env perl

use strict;
use warnings;

use Test::Validator::Declarative qw/ check_type_validation /;

my $year  = [ 1970, 1999 .. 2015, 3000 ];
my $month = [ 1 .. 12 ];
my $day   = [ 1 .. 31 ];
check_type_validation(
    type => 'ymd',
    good => [
        map {
            my $d = $_;
            map {
                my $m = $_;
                map {
                    my $y = $_;
                    sprintf( '%04d-%02d-%02d', $y, $m, $d );
                    } @$year
                } @$month
        } @$day
    ],
    bad => [
        ( map { ( "$_$_$_$_-$_$_-$_$_", "$_$_$_$_/$_$_/$_$_" ) } ( 0 .. 9 ) ),
        '1970-00-00',
        '3001-01-01',
        '',               # empty string
        'some string',    # arbitrary string
        v5.10.2,          # v-string
        sub { return 'TRUE' },    # coderef
        0, '1.00', '0.1', '-1.00', '-0.1', -1, -10, -123.456e10,
    ]
);

