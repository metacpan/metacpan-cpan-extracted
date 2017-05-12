#!/usr/bin/perl
use strict;
use Test::More tests => 12;
use Time::Piece::MySQL;

my $lt = localtime;
isa_ok( $lt, 'Time::Piece' );

my $gmt = gmtime;
isa_ok( $gmt, 'Time::Piece' );

for my $t ( $lt, $gmt )
{
    is( $t->mysql_date, $t->ymd );
    is( $t->mysql_time, $t->hms );
    is( $t->mysql_datetime, join ' ', $t->ymd, $t->hms );
}

my $t = Time::Piece->from_mysql_datetime( $lt->mysql_datetime );

isa_ok( $t, 'Time::Piece' );

is( $t->mysql_datetime, $lt->mysql_datetime );

my $t2 = Time::Piece->from_mysql_date( $lt->mysql_date );
isa_ok( $t2, 'Time::Piece' );

is( $t2->ymd, $lt->ymd );
