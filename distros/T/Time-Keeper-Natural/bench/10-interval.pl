#!perl
use strict; use warnings; use utf8;
BEGIN { require './bench/common.pl' }
use Time::Keeper; use Time::Keeper::Natural;
local $Time::Keeper::CLOCK = pinned();
my $n = Time::Keeper::Natural->new(zone => 'Europe/London', locale => 'en-GB');
mark_rate("parse_interval('15–17 Oct 2026')", sub { my @i = $n->parse_interval('15–17 Oct 2026') }, 20_000);
done();
