#!perl
use strict; use warnings;
BEGIN { require './bench/common.pl' }
use Time::Keeper; use Time::Piece (); use DateTime;
my ($a, $b) = (1760000000, 1795000000);
my ($ta, $tb) = map { Time::Keeper->from_epoch($_) } $a, $b;
my ($pa, $pb) = map { scalar Time::Piece::gmtime($_) } $a, $b;
my ($da, $db) = map { DateTime->from_epoch(epoch => $_) } $a, $b;
my $tk = rate(sub { $tb - $ta }, 'Time::Keeper');
mark('$b - $a', $tk, rate(sub { $pb - $pa }, 'Time::Piece'), 1, 'Time::Piece');
mark('$b - $a', $tk, rate(sub { $db - $da }, 'DateTime'), 10, 'DateTime');
done();
