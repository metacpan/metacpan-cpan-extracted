use strict;
use warnings;

BEGIN {
  $ENV{TZ} = "WET";
};

use Test::More tests => 10;
use Time::Piece::MySQL;
use Time::Piece::Over24;

my $t = localtime->from_over24("2015-03-28 24:00:00");
is $t->datetime, "2015-03-29T00:00:00", "DST before start";
is $t->isdst , 0 , "isdst before start";

$t = localtime->from_over24("2015-03-28 25:00:00");
is $t->datetime, "2015-03-29T02:00:00", "DST start";
is $t->isdst , 1 , "isdst 1 start";

$t = localtime->from_over24("2015-10-24 24:00:00");
is $t->datetime, "2015-10-25T00:00:00", "DST before end";
is $t->isdst , 1 , "isdst 1 before end";

$t = localtime->from_over24("2015-10-24 25:00:00");
is $t->datetime, "2015-10-25T01:00:00", "DST last one hour start";
is $t->isdst , 1 , "isdst 1 end";

$t = localtime->from_over24("2015-10-24 26:00:00");
is $t->datetime, "2015-10-25T01:00:00", "DST end";
is $t->isdst , 0 , "isdst 0 end";
