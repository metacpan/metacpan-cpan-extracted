#!perl
use strict; use warnings;
BEGIN { require './bench/common.pl' }
use Time::Keeper; use Time::Keeper::Business;
my $l = Time::Keeper::Business->new(zone => 'Europe/London', hours => ['09:00-17:30']);
my $n = Time::Keeper::Business->new(zone => 'America/New_York', hours => ['09:00-17:00']);
my $both = $l->join($n, hours => 'both');
my $t = Time::Keeper->new(year => 2026, month => 10, day => 15, hour => 10, zone => 'Europe/London');
mark_rate('next_open on a both join', rate(sub { $both->next_open($t) }, 'both join'), 5e5);
done();
