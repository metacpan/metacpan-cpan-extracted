#!perl
use 5.010;
use strict;
use warnings;
use utf8;
use Test::More;

use Time::Keeper;

my $K = 'Time::Keeper';
my $D = 'Time::Keeper::Duration';
sub err { my $t = eval { $K->parse($_[0]) }; defined $t ? "parsed as $t" : $@ }

# What is refused, and where.
my @bad = (
    ['2026-13-01'          => qr/there is no month 13/,                'month 13'],
    ['2026-00-10'          => qr/there is no month 0/,                 'month 0'],
    ['2026-02-29'          => qr/2026-02 has no day 29/,               '29 February in a common year'],
    ['2026-02-30'          => qr/2026-02 has no day 30/,               '30 February'],
    ['2026-04-31'          => qr/2026-04 has no day 31/,               '31 April'],
    ['2026-367'            => qr/2026 has no day 367/,                 'day 367'],
    ['2026-366'            => qr/2026 has no day 366/,                 'day 366 of a common year'],
    ['2025-W53'            => qr/2025 has no ISO week 53/,             'week 53 of a 52-week year'],
    ['2026-W42-8'          => qr/no day 8 of a week/,                  'day 8 of a week'],
    ['2026-10-15T25:00'    => qr/at offset 13: the hour is past 24/,   'hour 25, and where'],
    ['2026-10-15T24:30'    => qr/24:00 is the only time in hour 24/,   '24:30'],
    ['2026-10-15T09:60'    => qr/the minute is past 59/,               'minute 60'],
    ['2026-10-15T09:00:61' => qr/the second is past 60/,               'second 61'],
    ['2026-10-15T23:59:60Z' => qr/there was no leap second then/,      'a leap second that was not'],
    ['2026-10-15T09:00+24:00' => qr/the offset is out of range/,       'an offset of a day'],
    ['2026-10-15T09:00:00x' => qr/at offset 19: text was left over/,   'text left over, and where'],
    ['2026-1-15'           => qr/at offset 5: digits were wanted/,     'a month in one digit'],
    ['26-10-15'            => qr/cannot parse '26-10-15'/,              'a two-digit year'],
    ['202610'              => qr/8 digits, or 7/,                      'year and month in the basic form'],
    ['+12026-1'            => qr/digits were wanted/,                  'an expanded year and a one-digit month'],
    ['-0000-01-01'         => qr/-0 is not a year/,                    'the year -0'],
    ['2026-10-15T09:00[Nowhere/Special]' => qr/no time zone named 'Nowhere\/Special'/, 'a zone that is not there'],
    ['2026-10-15T09:00[Asia/Tokyo'       => qr/a \] was wanted/,       'a bracket left open'],
    [''                    => qr/at offset 0/,                         'nothing'],
    ['yesterday'           => qr/cannot parse 'yesterday' at offset 0/, 'a word'],
    ['Fri, 32 Oct 2026 09:00:00 GMT' => qr/2026-10 has no day 32/,    'the 32nd'],
    ['Fri, 16 Oct 2026 09:00 XYZ' => qr/a zone was wanted/,            'a zone name it does not know'],
    ['@'                   => qr/digits were wanted/,                  'an @ alone'],
    ['@12x'                => qr/text was left over/,                  'an epoch with something after'],
);
like(err($_->[0]), $_->[1], "$_->[2]: '$_->[0]'") for @bad;
is(err('+12026'), 'parsed as +012026-01-01T00:00:00Z', 'an expanded year alone is a year, as ISO 8601 allows');
like(err('2026-10-15T09:00:00ü'), qr/at offset 19: text was left over/, 'an offset counts characters, not bytes');
like(err("é2026"), qr/at offset 0/, 'from the start');
ok(!defined $K->try_parse('2026-13-01'), 'try_parse gives undef for a bad month');
ok(!defined $K->try_parse('2026-10-15T09:00[Nowhere/Special]'), 'and for a zone that is not there');
{
    local $@ = 'left alone';
    $K->try_parse('nonsense');
    is($@, 'left alone', 'and leaves $@ as it was');
}

# Corners the mutants found.
like(err("Fri, 21 Nov 1997 9:55:06 GMT"), qr/a time HH:MM was wanted/, 'the more telling of two errors at one place');
is(err('21 Nov 55 09:55:06 GMT'), 'parsed as 1955-11-21T09:55:06Z', 'a two-digit mail year of 55 is 1955');
is(err('21 Nov 49 09:55:06 GMT'), 'parsed as 2049-11-21T09:55:06Z', 'and 49 is 2049');
is($K->strptime('2026-10-18 0', '%Y-%m-%d %w') . '', '2026-10-18T00:00:00Z', '%w 0 is Sunday');
is($K->parse_cldr('2026-10-15 5', 'y-MM-dd e') . '', '2026-10-15T00:00:00Z', 'CLDR e counts from the first day of the locale: Thursday is 5');
is($K->parse_cldr('2026-10-15 24:30', 'y-MM-dd kk:mm') . '', '2026-10-15T00:30:00Z', 'CLDR k 24 is the hour after midnight');

# Durations.
sub dur { my $d = eval { $D->parse($_[0]) }; defined $d ? "$d" : "died: $@" }
is(dur('P1Y2M3DT4H5M6.5S'), 'P1Y2M3DT4H5M6.5S', 'a duration');
is(dur('P3W'), 'P21D', 'weeks are days');
is(dur('PT36H'), 'PT36H', 'hours are not days');
is(dur('-P1D'), '-P1D', 'negative');
is(dur('P1M-2D'), 'P1M-2D', 'with a sign in a part, as iso8601 writes them');
is(dur('PT1.5H'), 'PT1H30M', 'a fraction of an hour');
is(dur('PT0,25M'), 'PT15S', 'of a minute, with a comma');
is(dur('pt1s'), 'PT1S', 'in lower case');
is(dur('PT0S'), 'PT0S', 'nothing');
like(dur('P'), qr/at least one unit/, 'P alone');
like(dur('P1.5D'), qr/are whole/, 'a fraction of a day');
like(dur('PT1.5H30M'), qr/only the last unit may have a fraction/, 'a fraction before the last unit');
like(dur('P1H'), qr/Y, M, W or D was wanted/, 'hours before the T');
like(dur('PT1D'), qr/H, M or S was wanted/, 'days after it');
like(dur('1D'), qr/starts with P/, 'no P');
like(dur('P1DT1H1D'), qr/H, M or S was wanted/, 'a part out of place');
{
    srand(21);
    my $bad = 0;
    for (1 .. 2000) {
        my $d = $D->new(months => int(rand(200)) - 100, days => int(rand(200)) - 100,
                        minutes => int(rand(2e5)) - 1e5, seconds => int(rand(200)) - 100,
                        nanoseconds => int(rand(2e9)) - 1e9);
        my $back = eval { $D->parse("$d") };
        $bad++ unless $back && join(',', $back->deltas) eq join(',', $d->deltas);
    }
    is($bad, 0, 'durations of every sign read back from their strings');
}

# Intervals.
sub iv { my @t = eval { $K->parse_interval(@_) }; @t ? join(' / ', @t) : "died: $@" }
is(iv('2026-10-01/2026-10-15'), '2026-10-01T00:00:00Z / 2026-10-15T00:00:00Z', 'start and end');
is(iv('2026-10-01T09:00Z/P1M'), '2026-10-01T09:00:00Z / 2026-11-01T09:00:00Z', 'start and duration');
is(iv('P1D/2026-10-15'), '2026-10-14T00:00:00Z / 2026-10-15T00:00:00Z', 'duration and end');
is(iv('2026-03-07T12:00/P1D', zone => 'America/New_York'), '2026-03-07T12:00:00-05:00 / 2026-03-08T12:00:00-04:00', 'in a zone');
like(iv('P1D/P2D'), qr/two durations and no time/, 'two durations');
like(iv('2026-10-01'), qr/two parts with a \/ between/, 'no /');
like(iv('2026-10-01/2026-13-01'), qr/no month 13/, 'a bad end');

# A pattern literal that shares its first byte with the text's character: the
# offset is the character's, and nothing warns of malformed UTF-8.
{
    require Time::Keeper::Time;
    my @warned;
    local $SIG{__WARN__} = sub { push @warned, @_ };
    my $v = eval { Time::Keeper::Time->parse_cldr('10月15日', 'H時', locale => 'ja') };
    ok(!defined $v, 'ja: a date is not an hour and its literal');
    like($@, qr/at offset 2: /, 'and the offset is the character after the hour');
    is_deeply([ grep { /Malformed/ } @warned ], [], 'with no malformed UTF-8 warning') or diag(join '', @warned);
    $v = eval { $K->parse_cldr('10月15日 15:30', 'y年M月d日 H:mm', locale => 'ja', zone => 'UTC') };
    like($@, qr/at offset 2: /, 'a date pattern the same');
    is_deeply([ grep { /Malformed/ } @warned ], [], 'and still none');
}

done_testing;
