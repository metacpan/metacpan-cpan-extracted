#!perl
use strict; use warnings;
BEGIN { require './bench/common.pl' }
use Time::Keeper; use Time::Keeper::Natural;
local $Time::Keeper::CLOCK = pinned();
my $n = Time::Keeper::Natural->new(zone => 'Europe/London', locale => 'en-GB');
mark_rate("parse('tomorrow')", sub { $n->parse('tomorrow') }, 1_200_000);
done();
