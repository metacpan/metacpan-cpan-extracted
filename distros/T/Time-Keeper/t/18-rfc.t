#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Time::Keeper;

my $K = 'Time::Keeper';
sub t { $K->new(@_) }

# RFC 3339, section 5.8, its own examples.
is(t(year => 1985, month => 4, day => 12, hour => 23, minute => 20, second => 50, nanosecond => 520_000_000)->rfc3339,
   '1985-04-12T23:20:50.520Z', '1985-04-12T23:20:50.52Z (a fraction is written in threes)');
is(t(year => 1996, month => 12, day => 19, hour => 16, minute => 39, second => 57, zone => '-08:00')->rfc3339,
   '1996-12-19T16:39:57-08:00', '1996-12-19T16:39:57-08:00');
is(t(year => 1990, month => 12, day => 31, hour => 23, minute => 59, second => 60)->rfc3339,
   '1990-12-31T23:59:60Z', '1990-12-31T23:59:60Z, a leap second');
is(t(year => 1990, month => 12, day => 31, hour => 15, minute => 59, second => 60, zone => '-08:00')->rfc3339,
   '1990-12-31T15:59:60-08:00', 'the same leap second in Pacific time');
is(t(year => 1937, month => 1, day => 1, hour => 12, second => 27, nanosecond => 870_000_000, zone => '+00:20')->rfc3339,
   '1937-01-01T12:00:27.870+00:20', '1937-01-01T12:00:27.87+00:20, the Netherlands before 1937');
ok(!eval { t(year => 2026, zone => 'floating')->rfc3339; 1 }, 'floating time has no RFC 3339 form');
ok(!eval { t(year => 10000)->rfc3339; 1 }, 'nor a five-digit year');
is(t(year => 2026, nanosecond => 5)->rfc3339, '2026-01-01T00:00:00.000000005Z', 'nanoseconds');

# iso8601's precision.
my $p = t(year => 2026, month => 10, day => 15, hour => 9, nanosecond => 123_456_789);
is($p->iso8601(precision => 0), '2026-10-15T09:00:00Z', 'precision 0');
is($p->iso8601(precision => 3), '2026-10-15T09:00:00.123Z', 'precision 3 truncates');
is($p->iso8601(precision => 9), '2026-10-15T09:00:00.123456789Z', 'precision 9');
is(t(year => 2026)->iso8601(precision => 2), '2026-01-01T00:00:00.00Z', 'zeros when asked for');
ok(!eval { $p->iso8601(precision => 10); 1 }, 'not 10');
ok(!eval { $p->iso8601(digits => 3); 1 }, 'nor another option');

# RFC 5322 (which replaced RFC 2822), section A.1.1's example.
is(t(year => 1997, month => 11, day => 21, hour => 9, minute => 55, second => 6, zone => '-06:00')->rfc2822,
   'Fri, 21 Nov 1997 09:55:06 -0600', 'Fri, 21 Nov 1997 09:55:06 -0600');
is(t(year => 2026, month => 7, day => 4, hour => 12, zone => 'Europe/London')->rfc2822,
   'Sat, 04 Jul 2026 12:00:00 +0100', 'in a named zone');
is(t(year => 2026, nanosecond => 999_999_999)->rfc2822, 'Thu, 01 Jan 2026 00:00:00 +0000', 'no fraction');
ok(!eval { t(year => 2026, zone => 'floating')->rfc2822; 1 }, 'floating time has none');

# RFC 9110, section 5.6.7's example.
is(t(year => 1994, month => 11, day => 6, hour => 8, minute => 49, second => 37)->http_date,
   'Sun, 06 Nov 1994 08:49:37 GMT', 'Sun, 06 Nov 1994 08:49:37 GMT');
is(t(year => 1994, month => 11, day => 6, hour => 17, minute => 49, second => 37, zone => 'Asia/Tokyo')->http_date,
   'Sun, 06 Nov 1994 08:49:37 GMT', 'always in GMT, whatever the zone');

# RFC 9557's suffix.
is(t(year => 1996, month => 12, day => 19, hour => 16, minute => 39, second => 57, zone => 'America/Los_Angeles')->rfc9557,
   '1996-12-19T16:39:57-08:00[America/Los_Angeles]', '1996-12-19T16:39:57-08:00[America/Los_Angeles]');
is(t(year => 2026, zone => 'US/Pacific')->rfc9557, '2026-01-01T00:00:00-08:00[US/Pacific]', 'a link keeps its own name');
is(t(year => 2026)->rfc9557, '2026-01-01T00:00:00+00:00[UTC]', 'UTC');
is(t(year => 2026, zone => '+05:30')->rfc9557, '2026-01-01T00:00:00+05:30[+05:30]', 'a fixed offset');
is(t(year => 2026, zone => 'floating')->rfc9557, '2026-01-01T00:00:00', 'floating time has neither');

# ymd and its kin.
my $d = t(year => 2026, month => 3, day => 5, hour => 7, minute => 8, second => 9);
is_deeply([$d->ymd, $d->ymd('/'), $d->mdy, $d->dmy('.'), $d->hms, $d->hms(''), $d->date, $d->time],
          ['2026-03-05', '2026/03/05', '03-05-2026', '05.03.2026', '07:08:09', '070809', '2026-03-05', '07:08:09'],
          'ymd, mdy, dmy, hms, date and time');
is(t(year => -44, month => 3, day => 15)->ymd, '-0044-03-15', 'a year before Christ');
is(t(year => 12026)->ymd, '12026-01-01', 'a five-digit year');

done_testing;
