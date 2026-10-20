#!perl
use strict; use warnings;
BEGIN { require './bench/common.pl' }
use Time::Keeper; use Time::Keeper::Natural;
local $Time::Keeper::CLOCK = pinned();
my $n = Time::Keeper::Natural->new(zone => 'Europe/London', locale => 'en');
mark_rate("parse('next Tuesday at 3 pm')", sub { $n->parse('next Tuesday at 3 pm') }, 220_000);
done();
