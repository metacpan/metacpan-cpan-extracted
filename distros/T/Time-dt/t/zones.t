#!/usr/bin/perl

use warnings;
use strict;

use Test::More no_plan =>;#<

use Time::dt qw(dt strptime read_dt);

my $t = dt(1370322852);

# TODO your zone/tz files make this difficult to test
#is($t->dt, "2013-06-03 22:14:12 PDT") or die "failure";

# also... missing zones => silently use UTC and hate yourself
is($t->zdt("EST"), "2013-06-04 00:14:12 EST");

is(strptime("2013-06-04 01:14:12 EDT"), 1370322852);

my $t2 = read_dt("2013-06-04 01:14:12 EDT");
is($t2->epoch, 1370322852);

# vim:ts=2:sw=2:et:sta
