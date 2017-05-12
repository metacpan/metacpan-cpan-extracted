#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;

plan tests => 72;

use Time::Zone::Olson;
use Time::C;

# test all the Time::C constructors thoroughly

sub abs_diff { my ($x, $y, $z) = @_; return abs( $x - $y ) <= $z; }

my $epoch = time;
my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) =
  gmtime($epoch);

sub same_time {
    my $accuracy = shift;
    my ($s2, $mi2, $h2, $d2, $m2, $y2, $wd2, $yd2, $dst2) = gmtime();

    return 0 if $year != $y2;
    return 1 if $accuracy eq 'year';
    return 0 if $mon != $m2;
    return 1 if $accuracy eq 'month';
    return 0 if $mday != $d2;
    return 1 if $accuracy eq 'day';
    return 0 if $hour != $h2;
    return 1 if $accuracy eq 'hour';
    return 0 if $min != $mi2;
    return 1 if $accuracy eq 'minute';
    return 0 if $sec != $s2;
    return 1;
}

# new
{ my $t = Time::C->new();
    is (abs_diff($epoch, $t->epoch, my $max = 2), 1, "->new() constructor within limits"); }
{ my $t = Time::C->new(2016);
    is ($t->epoch, 1451606400, "->new(2016) constructor gave correct epoch"); }
{ my $t = Time::C->new(2016,3);
    is ($t->epoch, 1456790400, "->new(2016,3) constructor gave correct epoch"); }
{ my $t = Time::C->new(2016,3,26);
    is ($t->epoch, 1458950400, "->new(2016,3,26) constructor gave correct epoch"); }
{ my $t = Time::C->new(2016,3,26,4);
    is ($t->epoch, 1458964800, "->new(2016,3,26,4) constructor gave correct epoch"); }
{ my $t = Time::C->new(2016,3,26,4,51);
    is ($t->epoch, 1458967860, "->new(2016,3,26,4,51) constructor gave correct epoch"); }
{ my $t = Time::C->new(2016,3,26,4,51,38);
    is ($t->epoch, 1458967898, "->new(2016,3,26,4,51,38) constructor gave correct epoch"); }
{ my $t = Time::C->new(2016,3,26,4,51,38, "Europe/Stockholm");
    is ($t->epoch, 1458964298, '->new(2016,3,26,4,51,38,"Europe/Stockholm") constructor gave correct epoch'); }
{ my $t = Time::C->new(2016,3,27,4,51,38, "Europe/Stockholm");
    is ($t->epoch, 1459047098, '->new(2016,3,27,4,51,38,"Europe/Stockholm") constructor gave correct epoch'); }

# mktime
{ my $t = eval { Time::C->mktime(); };
    ok (not(defined($t)), "->mktime() constructor errored") or diag "\$t is defined: '$t'";
    like ($@, qr/^Could not mktime: No date specified and no time given[.]/, "->mktime() constructor errored out correctly"); }
{ my $t = Time::C->mktime(year => 2016); is ($t->epoch, 1451606400, "->mktime(year => 2016) constructor gave correct epoch"); }
SKIP: { my $t = Time::C->mktime(month => 3);
    skip "Year changed since we started.", 3 unless same_time('year');
    is ($t->year, $year + 1900, "->mktime(month => 3) constructor gave correct year");
    is ($t->month, 3, "->mktime(month => 3) constructor gave correct month");
    is ($t->day, 1, "->mktime(month => 3) constructor gave correct day"); }
{ my $t = eval { Time::C->mktime(mday => 26); };
    ok (not(defined($t)), "->mktime(mday => 26) constructor errored") or diag "\t is defined: '$t'";
    like ($@, qr/^Could not mktime: No date specified and no time given[.]/, "->mktime(mday => 26) constructor errored out correctly"); }
SKIP: { my $t = Time::C->mktime(week => 12);
    skip "Year changed since we started.", 3 unless same_time('year');
    is ($t->year, $year + 1900, "->mktime(week => 12) constructor gave correct year");
    is ($t->week, 12, "->mktime(week => 12) constructor gave correct week");
    is ($t->day_of_week, 1, "->mktime(week => 12) constructor gave correct day of week"); }
{ my $t = eval { Time::C->mktime(wday => 6); };
    ok (not(defined($t)), "->mktime(wday => 6) constructor errored") or diag "\t is defined: '$t'";
    like ($@, qr/^Could not mktime: No date specified and no time given[.]/, "->mktime(wday => 6) constructor errored out correctly"); }
SKIP: { my $t = Time::C->mktime(yday => 86);
    skip "Year changed since we started.", 3 unless same_time('year');
    is ($t->year, $year + 1900, "->mktime(yday => 86) constructor gave correct year");
    is ($t->month, 3, "->mktime(yday => 86) constructor gave correct month");
    is (abs_diff($t->day, 26, my $max = 1), 1, "->mktime(yday => 86) constructor day within limits"); }
SKIP: { my $t = Time::C->mktime(hour => 4);
    skip "Day changed since we started.", 4 unless same_time('day');
    is ($t->year, $year + 1900, "->mktime(hour => 4) gave correct year");
    is ($t->month, $mon + 1, "->mktime(hour => 4) gave correct month");
    is ($t->day, $mday, "->mktime(hour => 4) gave correct day");
    is ($t->hour, 4, "->mktime(hour => 4) gave correct hour"); }
SKIP: { my $t = Time::C->mktime(minute => 51);
    skip "Hour changed since we started.", 5 unless same_time('hour');
    is ($t->year, $year + 1900, "->mktime(minute => 51) gave correct year");
    is ($t->month, $mon + 1, "->mktime(minute => 51) gave correct month");
    is ($t->day, $mday, "->mktime(minute => 51) gave correct day");
    is ($t->hour, $hour, "->mktime(minute => 51) gave correct hour");
    is ($t->minute, 51, "->mktime(minute => 51) gave correct minute"); }
SKIP: { my $t = Time::C->mktime(second => 38);
    skip "Minute changed since we started.", 6 unless same_time('minute');
    is ($t->year, $year + 1900, "->mktime(second => 38) gave correct year");
    is ($t->month, $mon + 1, "->mktime(second => 38) gave correct month");
    is ($t->day, $mday, "->mktime(second => 38) gave correct day");
    is ($t->hour, $hour, "->mktime(second => 38) gave correct hour");
    is ($t->minute, $min, "->mktime(second => 38) gave correct minute");
    is ($t->second, 38, "->mktime(second => 38) gave correct second"); }
{ my $t = Time::C->mktime(year => 2016, month => 3);
    is ($t->epoch, 1456790400, "->mktime(year, month) gave correct epoch"); }
{ my $t = Time::C->mktime(year => 2016, mday => 26);
    is ($t->epoch, 1451606400, "->mktime(year, mday) gave correct epoch (mday ignored)"); }
{ my $t = Time::C->mktime(year => 2016, week => 12);
    is ($t->epoch, 1458518400, "->mktime(year, week) gave correct epoch"); }
{ my $t = Time::C->mktime(year => 2016, wday => 6);
    is ($t->epoch, 1451606400, "->mktime(year, wday) gave correct epoch (wday ignored)"); }
{ my $t = Time::C->mktime(year => 2016, yday => 86);
    is ($t->epoch, 1458950400, "->mktime(year, yday) gave correct epoch"); }
{ my $t = Time::C->mktime(year => 2016, hour => 4);
    is ($t->epoch, 1451620800, "->mktime(year, hour) gave correct epoch"); }
{ my $t = Time::C->mktime(year => 2016, minute => 51);
    is ($t->epoch, 1451609460, "->mktime(year, minute) gave correct epoch"); }
{ my $t = Time::C->mktime(year => 2016, second => 38);
    is ($t->epoch, 1451606438, "->mktime(year, second) gave correct epoch"); }
{ my $t = Time::C->mktime(year => 2016, month => 3, mday => 26);
    is ($t->epoch, 1458950400, "->mktime(year, month, day) gave correct epoch"); }
{ my $t = Time::C->mktime(year => 2016, month => 3, week => 1);
    is ($t->epoch, 1456790400, "->mktime(year, month, week) gave correct epoch (week ignored)"); }
{ my $t = Time::C->mktime(year => 2016, month => 3, wday => 6);
    is ($t->epoch, 1456790400, "->mktime(year, month, wday) gave correct epoch (wday ignored)"); }
{ my $t = Time::C->mktime(year => 2016, month => 3, week => 1, wday => 6);
    is ($t->epoch, 1456790400, "->mktime(year, month, week, wday) gave correct epoch (week, wday ignored)"); }
{ my $t = Time::C->mktime(year => 2016, month => 3, yday => 1);
    is ($t->epoch, 1456790400, "->mktime(year, month, yday) gave correct epoch (yday ignored)"); }
{ my $t = Time::C->mktime(year => 2016, week => 12);
    is ($t->epoch, 1458518400, "->mktime(year, week) gave correct epoch"); }
{ my $t = Time::C->mktime(year => 2016, week => 12, wday => 6);
    is ($t->epoch, 1458950400, "->mktime(year, week, wday) gave correct epoch"); }
{ my $t = Time::C->mktime(year => 2016, week => 12, mday => 26);
    is ($t->epoch, 1458518400, "->mktime(year, week, mday) gave correct epoch (mday ignored)"); }
{ my $t = Time::C->mktime(year => 2016, week => 12, yday => 86);
    is ($t->epoch, 1458518400, "->mktime(year, week, yday) gave correct epoch (yday ignored)"); }
{ my $t = Time::C->mktime(year => 2016, yday => 86, mday => 1);
    is ($t->epoch, 1458950400, "->mktime(year, yday, mday) gave correct epoch (mday ignored)"); }
{ my $t = Time::C->mktime(year => 2016, yday => 86, wday => 1);
    is ($t->epoch, 1458950400, "->mktime(year, yday, wday) gave correct epoch (wday ignored)"); }

# localtime

SKIP: {
  my $tz = eval { Time::Zone::Olson->new({timezone => $ENV{TZ}}); };
  skip "Could not get a usable timezone from the environment.", 7 if not defined $tz;

  my ($l_sec, $l_min, $l_hour, $l_mday, $l_mon, $l_year, $l_wday, $l_yday, $isdst)
    = localtime($epoch);

  { my $t = Time::C->localtime($epoch);
      is ($t->epoch, $epoch, "->localtime($epoch) constructor gave correct epoch");
      is ($t->year, $l_year + 1900, "->localtime($epoch) constructor gave correct year");
      is ($t->month, $l_mon + 1, "->localtime($epoch) constructor gave correct month");
      is ($t->day, $l_mday, "->localtime($epoch) constructor gave correct day of month");
      is ($t->hour, $l_hour, "->localtime($epoch) constructor gave correct hour");
      is ($t->minute, $l_min, "->localtime($epoch) constructor gave correct minute");
      is ($t->second, $l_sec, "->localtime($epoch) constructor gave correct second"); }
}

# gmtime

{ my $t = Time::C->gmtime($epoch);
    is ($t->epoch, $epoch, "->gmtime($epoch) constructor gave correct epoch"); }

# now

SKIP: {
  my $tz = eval { Time::Zone::Olson->new({timezone => $ENV{TZ}}); };
  skip "Could not get a usable timezone from the environment.", 1 if not defined $tz;

  my $epoch = time;
  my ($l_sec, $l_min, $l_hour, $l_mday, $l_mon, $l_year, $l_wday, $l_yday, $isdst)
    = localtime($epoch);

  { my $t = Time::C->now();
      is (abs_diff($epoch, $t->epoch, my $max = 2), 1, "->now() constructor within limits"); }
}

# now_utc

{
  my $epoch = time;
  { my $t = Time::C->now_utc();
      is (abs_diff($epoch, $t->epoch, my $max = 2), 1, "->now_utc() constructor within limits"); }
}

# from_string

{ my $t = Time::C->from_string("2016-03-26T04:51:38Z");
    is ($t->epoch, 1458967898, '->from_string("2016-03-26T04:51:38Z") constructor gave correct epoch'); }
{ my $t = Time::C->from_string("lör 26 mar 2016 04:51:38", format => "%a %d %b %Y %H:%M:%S", locale => "sv_SE");
    is ($t->epoch, 1458967898, '->from_string("lör 26 mar 2016 04:51:38", format => "%a %d %b %Y %H:%M:%S", locale => "sv_SE") constructor gave correct epoch'); }

# strptime

{ my $t = Time::C->strptime("lör 26 mar 2016 04:51:38", "%a %d %b %Y %H:%M:%S", locale => "sv_SE");
    is ($t->epoch, 1458967898, '->strptime("lör 26 mar 2016 04:51:38", "%a %d %b %Y %H:%M:%S", locale => "sv_SE") constructor gave correct epoch'); }


#done_testing;
