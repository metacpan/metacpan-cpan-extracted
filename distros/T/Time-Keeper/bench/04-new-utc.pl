#!perl
use strict; use warnings;
BEGIN { require './bench/common.pl' }
use Time::Keeper; use Time::Piece (); use Time::Local (); use DateTime;
my $tk = rate(sub { Time::Keeper->new(year => 2026, month => 10, day => 15, hour => 9, minute => 5, second => 7) }, 'Time::Keeper');
mark('new from fields, UTC', $tk, rate(sub { Time::Piece::gmtime(Time::Local::timegm(7, 5, 9, 15, 9, 2026)) }, 'Time::Piece'), 1, 'Time::Piece');
mark('new from fields, UTC', $tk, rate(sub { DateTime->new(year => 2026, month => 10, day => 15, hour => 9, minute => 5, second => 7, time_zone => 'UTC') }, 'DateTime'), 10, 'DateTime');
done();
