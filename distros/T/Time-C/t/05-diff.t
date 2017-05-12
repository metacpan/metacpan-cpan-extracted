#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 35;

use Time::D;
use Time::C;

my $d = Time::D->new(0);
isa_ok ($d, "Time::D");
is ("$d", "now", "when base and comp are the same, stringifies to 'now' correctly");
$d->hours++;
is ($d->base, 0, "base not affected after changing the hours");
is ($d->comp, 3600, "comp changed after hours changed by 1");
$d->hours = 5;
is ($d->comp, 5*3600, "comp changed after hours changed to 5");
$d->minutes = $d->seconds = 10;
$d->years = $d->months = $d->days = 1;
my ($sign, $year, $month, $week, $day, $hour, $min, $sec) = $d->to_array();
is ($sign, '+', "correct sign");
is ($year, 1, "correct year");
is ($month, 1, "correct month");
is ($week, 0, "correct week");
is ($day, 1, "correct day");
is ($hour, 5, "correct hour");
is ($min, 10, "correct minute");
is ($sec, 10, "correct second");
is ("$d", "in 1 year, and 1 month", "correct stringification");
is ($d->to_string(1), "in 1 year", "correct ->to_string(1)");
is ($d->to_string(2), "in 1 year, and 1 month", "correct ->to_string(2)");
is ($d->to_string(3), "in 1 year, 1 month, and 1 day", "correct ->to_string(3)");
is ($d->to_string(4), "in 1 year, 1 month, 1 day, and 5 hours", "correct ->to_string(4)");
is ($d->to_string(5), "in 1 year, 1 month, 1 day, 5 hours, and 10 minutes", "correct ->to_string(5)");
is ($d->to_string(6), "in 1 year, 1 month, 1 day, 5 hours, 10 minutes, and 10 seconds", "correct ->to_string(6)");
is (Time::C->gmtime($d->comp), "1971-02-02T05:10:10Z", "correct time from ->comp");
$d->sign = '-';
is ($d->to_string(6), "1 year, 1 month, 2 days, 5 hours, 10 minutes, and 10 seconds ago", "correct ->to_string(6) after sign change");
is (Time::C->gmtime($d->comp), "1968-11-29T18:49:50Z", "correct time from ->comp after sign change");
$d->years = 0;
is ($d->to_string(6), "1 month, 2 days, 5 hours, 10 minutes, and 10 seconds ago", "correct ->to_string(6) after setting ->years = 0");

my $t_base = Time::C->new(2016,10,10,12,0,0);
my $t_after = Time::C->new(2017,10,13,12,15,0);
my $t_before = Time::C->new(2015,10,7,11,45,0);

my $d2 = Time::D->new($t_base->epoch, $t_after->epoch);
is ($d2->to_string(7), "in 1 year, 3 days, and 15 minutes", "d2 diff correct");

my $d3 = Time::D->new($t_base->epoch, $t_before->epoch);
is ($d3->to_string(7), "1 year, 3 days, and 15 minutes ago", "d3 diff correct");

$d2->sign = '-';
is ($d2->comp, $t_before->epoch + 3600*24, "d2->comp changed epoch correctly by changing sign");
is ($d2->to_string(7), "1 year, 2 days, and 15 minutes ago", "d2 diff correct after changing sign");

my $t2_base = Time::C->new(2016,10,10,15);
my $t2_after = Time::C->new(2017,12,13,22,15);
my $t2_before = Time::C->new(2015,8,7,7,45);

my $d4 = Time::D->new($t2_base->epoch, $t2_after->epoch);
is ($d4->to_string(7), "in 1 year, 2 months, 3 days, 7 hours, and 15 minutes", "d4 diff correct");

my $d5 = Time::D->new($t2_base->epoch, $t2_before->epoch);
is ($d5->to_string(7), "1 year, 2 months, 3 days, 7 hours, and 15 minutes ago", "d5 diff correct");

$d5->sign = '+';
is ($d5->comp, $t2_after->epoch+24*3600, "d5->comp has correct epoch");
is (Time::C->gmtime($d5->comp), "2017-12-14T22:15:00Z", "d5->comp represents the correct time");

my $d6 = Time::C->new(2016,03,10,21,0,5)->diff(Time::C->new(2016,02,20,23,0,40));
is ($d6->to_string(7), "2 weeks, 4 days, 21 hours, 59 minutes, and 25 seconds ago", "d6 correct");
$d6->sign = '+';
is ($d6->to_string(7), "in 2 weeks, 4 days, 21 hours, 59 minutes, and 25 seconds", "d6 with changed sign correct");
is (Time::C->gmtime($d6->comp), "2016-03-29T18:59:30Z", "d6 with changed sign correct time");
