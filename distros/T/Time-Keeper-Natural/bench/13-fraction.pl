#!perl
use strict; use warnings;
BEGIN { require './bench/common.pl' }
use Time::Keeper; use Time::Keeper::Natural;
local $Time::Keeper::CLOCK = pinned();
my $n = Time::Keeper::Natural->new(zone => 'Europe/London', locale => 'en-GB');
mark_rate("parse_duration('1.5 hours')", sub { $n->parse_duration('1.5 hours') }, 80_000);
done();
