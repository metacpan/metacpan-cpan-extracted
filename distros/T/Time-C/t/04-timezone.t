#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Time::C;

if (-e "/usr/share/zoneinfo/Europe/Stockholm" and -e "/usr/share/zoneinfo/America/New_York") {
    plan tests => 22;
} else {
    plan skip_all => "Can't determine if Olson timezone database is present";
}

my $t = Time::C->from_string("2000-01-01T00:00:00Z");
is ($t->epoch, 946684800, "right epoch for 2000-01-01T00:00:00Z");

my $t_1 = Time::C->from_string("2000-01-01T01:00:00+01:00");
is ($t_1->epoch, 946684800, "right epoch for 2001-01-01T01:00:00+01:00");

my $t_2 = Time::C->from_string("1999-12-31T23:00:00-01:00");
is ($t_2->epoch, 946684800, "right epoch for 1999-12-31T23:00:00-01:00");

my $t_3 = Time::C->new(2000,1,1,1,0,0,"Europe/Stockholm");
is ($t_3->epoch, 946684800, "right epoch for 2000-01-01T01:00:00 Europe/Stockholm");
is ($t_3->offset, 60, "right offset for 2000-01-01T01:00:00 Europe Stockholm");

my $t_4 = Time::C->new(2000,3,26,0,0,0,"Europe/Stockholm");
is ($t_4->epoch, 954025200, "right epoch for 2000-03-26T00:00:00 Europe/Stockholm");
is ($t_4->offset, 60, "right offset for 2000-03-26T00:00:00 Europe/Stockholm");

my $t_5 = Time::C->new(2000,3,26,1,59,59,"Europe/Stockholm");
is ($t_5->epoch, 954025200+3600+3600-1, "right epoch for 2000-03-26T01:59:59 Europe/Stockholm");
is ($t_5->offset, 60, "right offset for 2000-03-26T01:59:59 Europe/Stockholm");

$t_5->second++;

is ($t_5->epoch, 954025200+3600+3600, "right epoch after adding 1 second");
is ($t_5->offset, 120, "right offset after adding 1 second");
is ($t_5->string, "2000-03-26T03:00:00+02:00", "right stringification after adding 1 second");

my $t_6 = Time::C->new(2000,3,26,2,0,0,"Europe/Stockholm");
is ($t_6->epoch, 954025200+3600+3600, "right epoch after entering nonexistent time 2000-03-26T02:00:00 Europe/Stockholm");
is ($t_6->offset, 120, "right offset after entering nonexistent time 2000-03-26T02:00:00 Europe/Stockholm");

my $t_7 = Time::C->new(2000,10,29,1,0,0,"Europe/Stockholm");
is ($t_7->epoch, 972774000, "right epoch for 2000-10-29T01:00:00 Europe/Stockholm");
is ($t_7->offset, 120, "right offset for 2000-10-29T01:00:00 Europe/Stockholm");

my $t_8 = Time::C->new(2000,10,29,2,0,0, "Europe/Stockholm");
is ($t_8->epoch, 972774000+3600+3600, "right epoch for 2000-10-29T02:00:00 Europe/Stockholm");
is ($t_8->offset, 60, "right offset for 2000-10-29T02:00:00 Europe/Stockholm");

my $t_9 = Time::C->new(2016,11,6,1,0,0,"America/New_York");
is ($t_9->epoch, 1478408400, "right epoch for 2016-11-06T01:00:00 America/New_York");
is ($t_9->offset, -240, "right offset for 2016-11-06T01:00:00 America/New_York");

my $t_10 = Time::C->new(2016,11,6,2,0,0,"America/New_York");
is ($t_10->epoch, 1478408400+3600+3600, "right epoch for 2016-11-06T02:00:00 America/New_York");
is ($t_10->offset, -300, "right offset for 2016-11-06T02:00:00 America/New_York");
