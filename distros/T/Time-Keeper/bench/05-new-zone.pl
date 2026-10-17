#!perl
use strict; use warnings;
BEGIN { require './bench/common.pl' }
use Time::Keeper; use DateTime;
my $tz = DateTime::TimeZone->new(name => 'America/New_York');
my $tk = rate(sub { Time::Keeper->new(year => 2026, month => 10, day => 15, hour => 9, minute => 5, second => 7, zone => 'America/New_York') }, 'Time::Keeper');
mark('new from fields, America/New_York', $tk, rate(sub { DateTime->new(year => 2026, month => 10, day => 15, hour => 9, minute => 5, second => 7, time_zone => $tz) }, 'DateTime'), 10, 'DateTime');
done();
