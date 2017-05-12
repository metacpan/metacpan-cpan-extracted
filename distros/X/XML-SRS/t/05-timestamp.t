#!/usr/bin/perl

use strict;
use warnings;

use Test::More ('no_plan');

use_ok("XML::SRS::TimeStamp");

my $ts1 =
	XML::SRS::TimeStamp->new(year => 2010, month => 6, day => 2,
	hour => 15, minute => 12, second => 2, tz_offset => "+10:13");
my $ts2 =
	XML::SRS::TimeStamp->new(year => 2010, month => 6, day => 2,
	hour => 15, minute => 12, second => 2, tz_offset => "+1013");

ok($ts1->epoch == $ts2->epoch, "timestamps represent the same moment");

for my $ts ( $ts1, $ts2 ) {
	ok($ts,"create timstamp");

	like($ts->timestamptz, qr/2010-06-02/, "nice timestamptz date...");
	like($ts->timestamptz, qr/15:12:02/, "nice timestamptz time...");
	like($ts->timestamptz, qr/1013/, "nice timestamptz tz...");

	like($ts->timestamp, qr/2010-06-02/, "nice timestamp date...");
	like($ts->timestamp, qr/15:12:02/, "nice timestamp time...");

}
