#!perl
use strict; use warnings;
BEGIN { require './bench/common.pl' }
use Time::Keeper; use Time::Piece (); use DateTime;
my $e = 1760000000;
my $tk = rate(sub { my $t = Time::Keeper->from_epoch($e); $t->year + $t->month + $t->day }, 'Time::Keeper');
mark('from_epoch, year, month, day', $tk, rate(sub { my $t = Time::Piece::gmtime($e); $t->year + $t->mon + $t->mday }, 'Time::Piece'), 1, 'Time::Piece');
mark('from_epoch, year, month, day', $tk, rate(sub { my $t = DateTime->from_epoch(epoch => $e); $t->year + $t->month + $t->day }, 'DateTime'), 10, 'DateTime');
done();
