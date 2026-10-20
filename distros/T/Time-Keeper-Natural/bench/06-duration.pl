#!perl
use strict; use warnings;
BEGIN { require './bench/common.pl' }
use Time::Keeper; use Time::Keeper::Natural;
my $n = Time::Keeper::Natural->new(zone => 'Europe/London', locale => 'en-GB');
mark_rate("parse_duration('1 hour, 30 minutes')", sub { $n->parse_duration('1 hour, 30 minutes') }, 500_000);
done();
