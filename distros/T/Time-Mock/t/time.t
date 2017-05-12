#!/usr/bin/perl

use warnings;
use strict;

use Test::More qw(no_plan);

my $otime;
BEGIN {$otime = time;}

use Time::Mock;

my $time = time;

ok($time < $otime + 5);
Time::Mock->throttle(10);
alarm(5);
sleep(4);
alarm(0);
#warn scalar localtime;
ok(Time::Mock::Original::time < $otime + 2);
Time::Mock->throttle(10_000);
is(Time::Mock->throttle, 10_000) or die;
is(Time::Mock->throttle, 10_000);

Time::Mock::Original::sleep(1);
my $later = time;
ok($later > $otime + 10_000);
Time::Mock->throttle(1);

$otime = time;
ok($otime < $later);

{
  Time::Mock->throttle(1/10_000);
  my $slow = time;
  is(scalar(localtime), scalar(localtime($slow)));
}

# vim:ts=2:sw=2:et:sta
