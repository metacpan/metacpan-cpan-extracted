#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Time::Verbal;

my $now = time;

is Time::Verbal::distance($now, $now),      "less then a minute";
is Time::Verbal::distance($now, $now + 29), "less then a minute";
is Time::Verbal::distance($now, $now + 63), "1 minute";
is Time::Verbal::distance($now, $now + 89), "1 minute";
is Time::Verbal::distance($now, $now + 90), "2 minutes";
is Time::Verbal::distance($now, $now + 119), "2 minutes";
is Time::Verbal::distance($now, $now + 120), "2 minutes";
is Time::Verbal::distance($now, $now + 3700), "about 1 hour";
is Time::Verbal::distance($now, $now + 5400), "2 hours";
is Time::Verbal::distance($now, $now + 10800), "3 hours";
is Time::Verbal::distance($now, $now + 86405), "one day";
is Time::Verbal::distance($now, $now + 86400 * 300), "300 days";
is Time::Verbal::distance($now, $now + 86400 * 600), "over a year";
is Time::Verbal::distance($now, $now + 86400 * 1000), "over a year";
is Time::Verbal::distance($now, $now),      "less then a minute";
is Time::Verbal::distance($now, $now - 29), "less then a minute";
is Time::Verbal::distance($now, $now - 63), "1 minute";
is Time::Verbal::distance($now, $now - 3700), "about 1 hour";
is Time::Verbal::distance($now, $now - 10800), "3 hours";
is Time::Verbal::distance($now, $now - 86405), "one day";
is Time::Verbal::distance($now, $now - 86400 * 300), "300 days";
is Time::Verbal::distance($now, $now - 86400 * 600), "over a year";
is Time::Verbal::distance($now, $now - 86400 * 1000), "over a year";

done_testing;
