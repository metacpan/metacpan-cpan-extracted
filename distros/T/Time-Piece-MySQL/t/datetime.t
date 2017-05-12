#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 6;
use Time::Piece::MySQL;

my $t = Time::Piece->from_mysql_datetime('2012-02-11 05:45:37');
isa_ok( $t, 'Time::Piece' );
$t = Time::Piece->from_mysql_date('2012-02-11');
isa_ok( $t, 'Time::Piece' );

my @null = qw/ 0000-00-00 1000-01-01 9999-12-31 /;
for my $d (@null) {
    ok !defined Time::Piece->from_mysql_date($d), "$d is not in range";
}
ok !defined Time::Piece->from_mysql_date(undef), "null is not in range";

#
# What should we do with these dates?
# In some tests, @bad dates produced undef but @ugly dates produced
# Time::Piece objects in the following month.
#
my @bad = qw/ 2001-00-00 2001-00-31 2001-02-00 2001-04-00 /;
my @ugly = qw/ 2001-02-31 2001-04-31 2001-11-31 /;

