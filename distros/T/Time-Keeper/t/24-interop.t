#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Time::Keeper;

my $K = 'Time::Keeper';

# compare, and the lengths.
my @v = map { $K->new(year => 2026, month => $_, zone => 'Europe/Paris') } 3, 1, 2;
is_deeply([map { $_->month } sort { $K->compare($a, $b) } @v], [1, 2, 3], 'compare sorts');
is($K->compare($v[0], $v[0]), 0, 'and is 0 for the same instant');
is($K->compare($K->new(year => 2026, hour => 1, zone => 'floating'), $K->new(year => 2026, zone => 'Asia/Tokyo')), 1,
   'floating time compares wall clocks, as <=> does');
ok(!eval { $K->compare($v[0], 'x'); 1 }, 'compare needs two values');
is($K->new(year => 2028)->days_in_year, 366, 'days_in_year in a leap year');
is($K->new(year => 2026)->days_in_year, 365, 'and in another');
is_deeply([map { $K->new(year => 2028, month => $_)->days_in_quarter } 1, 4, 7, 10], [91, 91, 92, 92], 'days_in_quarter');
is($K->new(year => 2026, month => 2)->days_in_quarter, 90, 'and 90 in a common year');

# Rata Die, as DateTime counts it.
is_deeply([$K->new(year => 1)->utc_rd_values], [1, 0, 0], '1 January of the year 1 is day 1');
is_deeply([$K->new(year => 1970)->utc_rd_values], [719163, 0, 0], 'the epoch');
is_deeply([$K->new(year => 0, month => 12, day => 31, hour => 23, minute => 59, second => 59, nanosecond => 5)->utc_rd_values],
          [0, 86399, 5], 'the day before is day 0');
is_deeply([$K->new(year => 2016, month => 12, day => 31, hour => 23, minute => 59, second => 60, nanosecond => 7)->utc_rd_values],
          [736329, 86400, 7], 'a leap second is second 86400');
my $tokyo = $K->new(year => 1969, month => 12, day => 31, hour => 23, zone => 'Asia/Tokyo');
is_deeply([$tokyo->utc_rd_values], [719162, 50400, 0], 'in UTC');
is_deeply([$tokyo->local_rd_values], [719162, 82800, 0], 'and on the wall clock');
is_deeply([$K->new(year => 2026, hour => 5, zone => 'floating')->utc_rd_values], [739617, 18000, 0],
          'floating time is its wall clock');

# from_object, with objects that speak the protocol.
{
    package My::Zone;
    sub new { bless { name => $_[1] }, $_[0] }
    sub name { $_[0]{name} }
    package My::Time;
    sub new { my $c = shift; bless [@_], $c }
    sub utc_rd_values { @{ $_[0] }[0 .. 2] }
    sub time_zone { defined $_[0][3] ? My::Zone->new($_[0][3]) : undef }
    package My::Bare;
    sub new { my $c = shift; bless [@_], $c }
    sub utc_rd_values { @{ $_[0] } }
}
my @rd = $K->new(year => 2026, month => 10, day => 15, hour => 21, minute => 5, second => 7, nanosecond => 9)->utc_rd_values;
is($K->from_object(object => My::Bare->new(@rd))->rfc9557, '2026-10-15T21:05:07.000000009+00:00[UTC]',
   'an object with no zone is UTC');
is($K->from_object(object => My::Time->new(@rd, 'America/New_York'))->rfc9557,
   '2026-10-15T17:05:07.000000009-04:00[America/New_York]', 'its zone is taken by name');
is($K->from_object(object => My::Time->new(@rd, 'America/New_York'), zone => 'Asia/Tokyo')->zone_name, 'Asia/Tokyo',
   'zone overrides it');
is($K->from_object(object => My::Time->new(@rd, 'floating'))->iso8601, '2026-10-15T21:05:07.000000009',
   'a floating object gives floating time');
is($K->from_object(object => My::Time->new(@rd, '+0530'))->offset, 19800, 'an offset');
is($K->from_object(object => My::Bare->new(@rd), locale => 'fr')->locale, 'fr', 'and a locale');
is($K->from_object(object => My::Bare->new(736329, 86400, 7))->iso8601, '2016-12-31T23:59:60.000000007Z', 'a leap second');
my $round = $K->new(year => -44, month => 3, day => 15, hour => 12, nanosecond => 1, zone => 'Europe/Rome');
is($K->from_object(object => My::Time->new($round->utc_rd_values, 'Europe/Rome')), $round, 'a value back from its own values');
ok(!eval { $K->from_object(object => My::Bare->new(739904, 86400, 0)); 1 }, 'a leap second that was not one');
like($@, qr/no leap second then/, 'says so');
ok(!eval { $K->from_object(object => My::Bare->new(1, 2)); 1 }, 'two values, not three');
like($@, qr/gave 2 values/, 'says so');
ok(!eval { $K->from_object(object => My::Bare->new(1, 90000, 0)); 1 }, 'seconds out of range');
ok(!eval { $K->from_object(object => 'My::Bare'); 1 }, 'a class is not an object');
ok(!eval { $K->from_object(thing => 1); 1 }, 'an unknown argument');
ok(!eval { $K->from_object(object => My::Time->new(@rd, 'Nowhere/Special')); 1 }, 'a zone that is not there');

# An object with epoch but no utc_rd_values: Time::Piece, Time::Moment and the like.
{
    package My::Epochy;
    sub new { my ($c, %f) = @_; bless {%f}, $c }
    sub epoch { $_[0]{epoch} }
    sub nanosecond { $_[0]{nanosecond} }
    package My::Offsetty;
    our @ISA = ('My::Epochy');
    sub tzoffset { $_[0]{tzoffset} }
    package My::Nothing;
    sub new { bless {}, shift }
    package main;
}
is($K->from_object(object => My::Epochy->new(epoch => 1760000000, nanosecond => 123))->iso8601, '2025-10-09T08:53:20.000000123Z', 'an object with epoch and nanosecond');
is($K->from_object(object => My::Epochy->new(epoch => '1760000000.5'))->iso8601, '2025-10-09T08:53:20.500Z', 'an epoch with a fraction, as from_epoch reads it');
is($K->from_object(object => My::Offsetty->new(epoch => 1760000000, tzoffset => 19800))->zone_name, '+05:30', 'tzoffset gives a fixed zone');
is($K->from_object(object => My::Offsetty->new(epoch => 1760000000, tzoffset => 19800))->iso8601, '2025-10-09T14:23:20+05:30', 'the same instant there');
is($K->from_object(object => My::Offsetty->new(epoch => 1760000000, tzoffset => 0))->zone_name, 'UTC', 'a zero offset is UTC');
is($K->from_object(object => My::Offsetty->new(epoch => 1760000000, tzoffset => 19800), zone => 'Asia/Kolkata')->zone_name, 'Asia/Kolkata',
   'a zone given wins over tzoffset');
is($K->from_object(object => My::Epochy->new(epoch => 1760000000), locale => 'fr')->locale, 'fr', 'with a locale');
ok(!eval { $K->from_object(object => My::Nothing->new); 1 }, 'an object with neither method');
like($@, qr/an object with utc_rd_values or epoch is required/, 'says so');
ok(!eval { $K->from_object(object => My::Epochy->new(epoch => 1760000000, nanosecond => -1)); 1 }, 'a nanosecond out of range');
ok(!eval { $K->from_object(object => My::Offsetty->new(epoch => 1, tzoffset => 90000)); 1 }, 'an offset of more than a day');
SKIP: {
    skip 'Time::Piece is not installed', 4 unless eval { require Time::Piece; 1 };
    my $gm = Time::Piece->gmtime(1760000000);
    is($K->from_object(object => $gm)->iso8601, '2025-10-09T08:53:20Z', 'a Time::Piece from gmtime');
    is($K->from_object(object => $gm)->zone_name, 'UTC', 'is in UTC');
    my $lt = Time::Piece->localtime(1760000000);
    is($K->from_object(object => $lt)->epoch, 1760000000, 'a Time::Piece from localtime is the same instant');
    is($K->from_object(object => $lt, zone => 'local')->epoch, 1760000000, 'and with zone => local too');
}

SKIP: {
    skip 'DateTime is not installed', 4 unless eval { require DateTime; 1 };
    my $dt = DateTime->new(year => 2026, month => 10, day => 15, hour => 21, minute => 5, second => 7,
                           nanosecond => 123, time_zone => 'America/New_York');
    my $t = $K->from_object(object => $dt);
    is($t->rfc9557, '2026-10-15T21:05:07.000000123-04:00[America/New_York]', 'from a DateTime');
    my $back = DateTime->from_object(object => $t);
    is($back->epoch, $dt->epoch, 'and DateTime from a value');
    is($back->nanosecond, 123, 'to the nanosecond');
    is_deeply([$t->utc_rd_values], [$dt->utc_rd_values], 'the same Rata Die values');
}

done_testing;
