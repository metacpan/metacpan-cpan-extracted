#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Time::Keeper;

my $K = 'Time::Keeper';
sub p { my $t = eval { $K->parse(@_) }; defined $t ? "$t" : "died: $@" }

# ISO 8601-1:2019's forms, extended and basic.
my @iso = (
    ['2026-10-15'                   => '2026-10-15T00:00:00Z',        'a calendar date'],
    ['20261015'                     => '2026-10-15T00:00:00Z',        'in the basic form'],
    ['2026-10'                      => '2026-10-01T00:00:00Z',        'a month (reduced precision)'],
    ['2026'                         => '2026-01-01T00:00:00Z',        'a year'],
    ['2026-W42-4'                   => '2026-10-15T00:00:00Z',        'a week date'],
    ['2026W424'                     => '2026-10-15T00:00:00Z',        'in the basic form'],
    ['2026-W42'                     => '2026-10-12T00:00:00Z',        'a week (its Monday)'],
    ['2020-W53-7'                   => '2021-01-03T00:00:00Z',        'week 53 runs into the next year'],
    ['2026-288'                     => '2026-10-15T00:00:00Z',        'an ordinal date'],
    ['2026288'                      => '2026-10-15T00:00:00Z',        'in the basic form'],
    ['2024-366'                     => '2024-12-31T00:00:00Z',        'day 366 of a leap year'],
    ['2026-10-15T09:30:15'          => '2026-10-15T09:30:15Z',        'a date and time'],
    ['20261015T093015'              => '2026-10-15T09:30:15Z',        'in the basic form'],
    ['2026-10-15T09:30'             => '2026-10-15T09:30:00Z',        'without seconds'],
    ['2026-10-15T09'                => '2026-10-15T09:00:00Z',        'an hour alone'],
    ['2026-10-15T09:30:15.123456789' => '2026-10-15T09:30:15.123456789Z', 'nanoseconds'],
    ['2026-10-15T09:30:15,5'        => '2026-10-15T09:30:15.500Z',    'a decimal comma'],
    ['2026-10-15T09:30:15.1234567891' => '2026-10-15T09:30:15.123456789Z', 'digits past the ninth are dropped'],
    ['2026-10-15T09.5'              => '2026-10-15T09:30:00Z',        'a fraction of an hour'],
    ['2026-10-15T09:30.25'          => '2026-10-15T09:30:15Z',        'a fraction of a minute'],
    ['2026-10-15T24:00'             => '2026-10-16T00:00:00Z',        '24:00 is the end of the day'],
    ['2026-10-15T09:30:15Z'         => '2026-10-15T09:30:15Z',        'Z'],
    ['2026-10-15T09:30:15z'         => '2026-10-15T09:30:15Z',        'z'],
    ['2026-10-15T09:30:15+05:30'    => '2026-10-15T09:30:15+05:30',   'an offset'],
    ['2026-10-15T09:30:15+0530'     => '2026-10-15T09:30:15+05:30',   'in the basic form'],
    ['2026-10-15T09:30:15-08'       => '2026-10-15T09:30:15-08:00',   'hours alone'],
    ['2026-10-15T09:30:15+00:00'    => '2026-10-15T09:30:15Z',        'a zero offset is UTC'],
    ['2026-10-15 09:30:15'          => '2026-10-15T09:30:15Z',        'a space for the T, as RFC 3339 allows'],
    ['+012026-10-15'                => '+012026-10-15T00:00:00Z',     'an expanded year'],
    ['-000044-03-15'                => '-000044-03-15T00:00:00Z',     'a year before Christ'],
    ['0000-01-01'                   => '0000-01-01T00:00:00Z',        'the year 0'],
    # RFC 3339 section 5.8's examples.
    ['1985-04-12T23:20:50.52Z'      => '1985-04-12T23:20:50.520Z',    'RFC 3339: 1985-04-12T23:20:50.52Z'],
    ['1996-12-19T16:39:57-08:00'    => '1996-12-19T16:39:57-08:00',   'RFC 3339: 1996-12-19T16:39:57-08:00'],
    ['1990-12-31T23:59:60Z'         => '1990-12-31T23:59:60Z',        'RFC 3339: a leap second'],
    ['1990-12-31T15:59:60-08:00'    => '1990-12-31T15:59:60-08:00',   'RFC 3339: the same, in Pacific time'],
    ['1937-01-01T12:00:27.87+00:20' => '1937-01-01T12:00:27.870+00:20', 'RFC 3339: the Netherlands before 1937'],
    # RFC 9557.
    ['1996-12-19T16:39:57-08:00[America/Los_Angeles]' => '1996-12-19T16:39:57-08:00', 'RFC 9557: a zone'],
    ['2026-10-15T09:00:00+09:00[!Asia/Tokyo]'          => '2026-10-15T09:00:00+09:00', 'a critical zone that agrees'],
    ['2026-10-15T09:00:00[Asia/Tokyo]'                 => '2026-10-15T09:00:00+09:00', 'a zone without an offset'],
    ['2026-10-15T09:00:00+09:00[Asia/Tokyo][u-ca=gregory]' => '2026-10-15T09:00:00+09:00', 'the Gregorian calendar named'],
    ['2026-10-15T09:00:00+09:00[Asia/Tokyo][foo=bar]'  => '2026-10-15T09:00:00+09:00', 'an annotation it does not know, not critical'],
);
is(p($_->[0]), $_->[1], "$_->[2]: $_->[0]") for @iso;

is($K->parse('1996-12-19T16:39:57-08:00[America/Los_Angeles]')->zone_name, 'America/Los_Angeles', 'the zone is the bracket\'s');
is($K->parse('2026-10-15T09:00:00+00:00[Asia/Tokyo]') . '', '2026-10-15T18:00:00+09:00',
   'an offset that disagrees with a zone that is not critical: the offset fixes the instant');
like(p('2026-10-15T09:00:00+00:00[!Asia/Tokyo]'), qr/the zone is marked critical/, 'a critical zone that disagrees is refused');
is(Time::Keeper->parse('2026-10-15T09:00:00Z[u-ca=hebrew]')->calendar, 'hebrew', 'another calendar is read, since 0.05');
like(p('2026-10-15T09:00:00[!foo=bar]'), qr/critical annotation that is not known/, 'a critical annotation it does not know');
like(p('2026-10-15T09:00:00[Asia/Tokyo][Europe/London]'), qr/a second time zone/, 'two zones');
is($K->parse('2026-10-15T09:00', zone => 'Europe/London') . '', '2026-10-15T09:00:00+01:00', 'zone => for text without an offset');
is($K->parse('2026-10-15T09:00Z', zone => 'Europe/London') . '', '2026-10-15T09:00:00Z', 'but not for text with one');
is($K->parse('2026-03-08T02:30', zone => 'America/New_York', gap => 'forward') . '', '2026-03-08T03:30:00-04:00',
   'gap => for a time in a gap');
is($K->parse('2026-11-01T01:30', zone => 'America/New_York', overlap => 'later') . '', '2026-11-01T01:30:00-05:00',
   'overlap => for a time in an overlap');

# The mail and HTTP forms.
my @mail = (
    ['Fri, 21 Nov 1997 09:55:06 -0600' => '1997-11-21T09:55:06-06:00', 'RFC 5322 A.1.1'],
    ['Tue, 1 Jul 2003 10:52:37 +0200'  => '2003-07-01T10:52:37+02:00', 'RFC 5322 A.1.2'],
    ['Thu, 13 Feb 1969 23:32:54 -0330' => '1969-02-13T23:32:54-03:30', 'RFC 5322 A.1.3'],
    ['21 Nov 97 09:55:06 GMT'          => '1997-11-21T09:55:06Z',      'RFC 5322 A.6.2: no day name, a two-digit year'],
    ['Fri, 21 Nov 1997 09:55 EST'      => '1997-11-21T09:55:00-05:00', 'an obsolete zone name, no seconds'],
    ['Fri, 21 Nov 1997 09:55:06 PDT'   => '1997-11-21T09:55:06-07:00', 'PDT'],
    ['Fri, 21 Nov 1997 09:55:06 Z'     => '1997-11-21T09:55:06Z',      'a military letter is UTC with no local time'],
    ['Fri, 21 Nov 1997 09:55:06 (Central Standard Time) -0600' => '1997-11-21T09:55:06-06:00', 'a comment'],
    ['  fri,  21 nov 1997 09:55:06 -0600  ' => '1997-11-21T09:55:06-06:00', 'case and extra white space'],
    ['Thu, 01 Jan 70 00:00:00 +0000'   => '1970-01-01T00:00:00Z',      'a two-digit year of 70 is 1970'],
    ['Sun, 06 Nov 1994 08:49:37 GMT'   => '1994-11-06T08:49:37Z',      'RFC 9110 IMF-fixdate'],
    ['Sunday, 06-Nov-94 08:49:37 GMT'  => '1994-11-06T08:49:37Z',      'RFC 9110 obsolete RFC 850 form'],
    ['Sun Nov  6 08:49:37 1994'        => '1994-11-06T08:49:37Z',      'RFC 9110 obsolete asctime form'],
);
is(p($_->[0]), $_->[1], "$_->[2]: $_->[0]") for @mail;
like(p('Fri, 15 Oct 2026 09:00:00 +0000'), qr/2026-10-15 was a Thursday/, 'a day name that is not the date\'s is refused');

is(p('@1760000000'), '2025-10-09T08:53:20Z', 'an epoch after @');
is(p('@-1.5'), '1969-12-31T23:59:58.500Z', 'a negative one with a fraction');
is($K->parse('@0', zone => 'Asia/Tokyo') . '', '1970-01-01T09:00:00+09:00', 'in a zone');

# Every value written in its ISO 8601, RFC 3339, RFC 9557, RFC 2822 and HTTP
# forms reads back as the same instant.
{
    srand(19);
    my @zones = ('UTC', '+05:30', 'America/New_York', 'Europe/London', 'Australia/Lord_Howe', 'Asia/Kathmandu');
    my ($n, $bad) = (0, 0);
    for (1 .. 3000) {
        my $t = $K->from_epoch(int(rand(4e9)) . '.' . int(rand(1e9)), zone => $zones[int rand @zones]);
        for my $form (qw(iso8601 rfc3339 rfc9557)) {
            $n++;
            my $back = eval { $K->parse($t->$form) };
            $bad++, diag("$form: " . $t->$form . ' ' . ($@ || 'differs')) unless $back && $back == $t && $back->offset == $t->offset;
        }
        for my $form (qw(rfc2822 http_date)) {
            $n++;
            my $back = eval { $K->parse($t->$form) };
            $bad++, diag("$form: " . $t->$form . ' ' . ($@ || 'differs')) unless $back && $back->epoch == $t->epoch;
        }
    }
    is($bad, 0, "$n values in five forms read back as themselves");
}

done_testing;
