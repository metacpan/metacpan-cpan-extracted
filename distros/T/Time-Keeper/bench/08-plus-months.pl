#!perl
use strict; use warnings;
BEGIN { require './bench/common.pl' }
use Time::Keeper; use Time::Piece (); use DateTime;
my ($t, $tp, $dt) = (Time::Keeper->from_epoch(1760000000), scalar Time::Piece::gmtime(1760000000), DateTime->from_epoch(epoch => 1760000000));
my $tk = rate(sub { $t->plus(months => 1) }, 'Time::Keeper');
mark('plus(months => 1)', $tk, rate(sub { $tp->add_months(1) }, 'Time::Piece'), 1, 'Time::Piece');
mark('plus(months => 1)', $tk, rate(sub { $dt->clone->add(months => 1) }, 'DateTime'), 10, 'DateTime');
done();
