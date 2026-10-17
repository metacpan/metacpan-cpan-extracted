#!perl
use strict; use warnings;
BEGIN { require './bench/common.pl' }
use Time::Keeper; use Time::Piece (); use DateTime;
my $p = '%Y-%m-%d %H:%M:%S';
my ($t, $tp, $dt) = (Time::Keeper->from_epoch(1760000000), scalar Time::Piece::gmtime(1760000000), DateTime->from_epoch(epoch => 1760000000));
my $tk = rate(sub { $t->strftime($p) }, 'Time::Keeper');
mark("strftime('$p')", $tk, rate(sub { $tp->strftime($p) }, 'Time::Piece'), 1, 'Time::Piece');
mark("strftime('$p')", $tk, rate(sub { $dt->strftime($p) }, 'DateTime'), 20, 'DateTime');
done();
