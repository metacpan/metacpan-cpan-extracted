#!perl
use strict; use warnings;
BEGIN { require './bench/common.pl' }
use Time::Keeper; use Time::Piece (); use DateTime;
my $tk = rate(sub { Time::Keeper->now }, 'Time::Keeper');
mark('now', $tk, rate(sub { Time::Piece::gmtime() }, 'Time::Piece'), 1, 'Time::Piece');
mark('now', $tk, rate(sub { DateTime->now }, 'DateTime'), 10, 'DateTime');
done();
