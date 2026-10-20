#!perl
use strict; use warnings;
BEGIN { require './bench/common.pl' }
use Time::Keeper; use Time::Keeper::Natural;
local $Time::Keeper::CLOCK = pinned();
my $n = Time::Keeper::Natural->new(zone => 'Europe/London', locale => 'en-GB');
mark_rate("parse('in 3 days')", sub { $n->parse('in 3 days') }, 900_000);
done();
