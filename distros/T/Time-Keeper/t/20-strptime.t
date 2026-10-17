#!perl
use 5.010;
use strict;
use warnings;
use utf8;
use Test::More;
use Time::Piece ();

use Time::Keeper;

my $K = 'Time::Keeper';
sub sp { my $t = eval { $K->strptime(@_) }; defined $t ? "$t" : "died: $@" }

# Round trips: what strftime writes with each pattern, strptime reads back.
{
    my @pats = ('%Y-%m-%d %H:%M:%S', '%F %T', '%d/%m/%Y %I:%M:%S %p', '%a %b %e %H:%M:%S %Y', '%A, %B %d %Y %R:%S',
                '%Y-%j %T', '%G-W%V-%u %T', '%s', '%Y%m%d%H%M%S', '%D %T', '%y-%m-%d %k:%M:%S',
                '%C%y-%m-%d %H:%M:%S', '%Y-%m-%d %l:%M:%S %P', '%Y-%m-%dT%H:%M:%S.%N', '%Y-%m-%d %H:%M:%S.%3N',
                '%Y %U %a %T', '%Y %W %u %T', '%Y %U %w %T', '%c', '%x %X');
    srand(20);
    my ($n, $bad) = (0, 0);
    for (1 .. 1000) {
        my $t = $K->from_epoch(int(rand(3e9)) + 100_000_000);
        for my $p (@pats) {
            my $s = $t->strftime($p);
            my $back = eval { $K->strptime($s, $p) };
            my $want = $t;
            $want = $want->truncate(to => 'second') unless $p =~ /%N|%3N/;
            $want = $want->with(nanosecond => int($t->nanosecond / 1e6) * 1e6) if $p =~ /%3N/;
            $n++;
            next if $back && $back == $want;
            diag("'$p' wrote '$s', read " . ($back // "nothing: $@")) if $bad < 5;
            $bad++;
        }
    }
    is($bad, 0, "$n values written by strftime read back by strptime, through 20 patterns");
}

# Against Time::Piece's strptime.
{
    srand(21);
    my ($n, $bad) = (0, 0);
    for (1 .. 1000) {
        my $s = int(rand(3e9)) + 100_000_000;
        my $str = Time::Piece::gmtime($s)->strftime('%Y-%m-%d %H:%M:%S');
        for my $p ('%Y-%m-%d %H:%M:%S') {
            my $tp = Time::Piece->strptime($str, $p);
            my $mine = $K->strptime($str, $p);
            $n++;
            $bad++ unless $tp->epoch == $mine->epoch;
        }
    }
    is($bad, 0, "$n strings read as Time::Piece reads them");
    for my $c (['09:30', '%H:%M'], ['15/10', '%d/%m'], ['2026', '%Y'], ['10 15', '%m %d']) {
        my $tp = Time::Piece->strptime(@$c);
        is($K->strptime(@$c)->epoch, $tp->epoch, "missing fields default as Time::Piece's do: '$c->[0]' as '$c->[1]'");
    }
}

is(sp('Thu Oct 15 2026', '%a %b %d %Y'), '2026-10-15T00:00:00Z', 'names');
is(sp('THURSDAY october 15 2026', '%A %B %d %Y'), '2026-10-15T00:00:00Z', 'in any case');
is(sp('Thursday Oct 15 2026', '%a %B %d %Y'), '2026-10-15T00:00:00Z', 'long or short, whichever the pattern says');
like(sp('Fri Oct 15 2026', '%a %b %d %Y'), qr/2026-10-15 was a Thursday/, 'a weekday that is not the date\'s');
is(sp('12:30 AM', '%I:%M %p'), '1970-01-01T00:30:00Z', '12 AM is midnight');
is(sp('12:30 pm', '%I:%M %p'), '1970-01-01T12:30:00Z', '12 PM is noon');
like(sp('13:30 PM', '%I:%M %p'), qr/12-hour clock has no hour 13/, 'a 12-hour clock has no 13');
is(sp('69', '%y'), '1969-01-01T00:00:00Z', '%y 69 is 1969');
is(sp('68', '%y'), '2068-01-01T00:00:00Z', 'and 68 2068, as POSIX has it');
is(sp('20 26', '%C %y'), '2026-01-01T00:00:00Z', '%C and %y together');
is(sp('2026-10-15 09:00 +0530', '%Y-%m-%d %H:%M %z'), '2026-10-15T09:00:00+05:30', '%z');
is(sp('2026-10-15 09:00 -08:00', '%Y-%m-%d %H:%M %z'), '2026-10-15T09:00:00-08:00', '%z with a colon');
is(sp('2026-10-15 09:00 Z', '%Y-%m-%d %H:%M %z'), '2026-10-15T09:00:00Z', '%z Z');
is(sp('2026-10-15 09:00 UTC', '%Y-%m-%d %H:%M %Z'), '2026-10-15T09:00:00Z', '%Z UTC');
like(sp('2026-10-15 09:00 IST', '%Y-%m-%d %H:%M %Z'), qr/could mean more than one zone/, '%Z alone is ambiguous');
is(sp('2026-10-15 09:00 IST', '%Y-%m-%d %H:%M %Z', zone => 'Asia/Kolkata'), '2026-10-15T09:00:00+05:30',
   'unless the zone is given, and the abbreviation is its');
like(sp('2026-10-15 09:00 GMT', '%Y-%m-%d %H:%M %Z', zone => 'Asia/Kolkata'), qr/2026-10-15T09:00:00Z|abbreviation/,
   'GMT is UTC whatever zone is given');
like(sp('2026-07-15 09:00 GMT', '%Y-%m-%d %H:%M %Z', zone => 'Europe/London'), qr/2026-07-15T09:00:00Z/, 'GMT read as UTC');
like(sp('2026-07-15 09:00 EST', '%Y-%m-%d %H:%M %Z', zone => 'America/New_York'), qr/abbreviation then was EDT, not EST/,
   'an abbreviation that is not the zone\'s then');
is(sp('2026-11-01 01:30 EST', '%Y-%m-%d %H:%M %Z', zone => 'America/New_York'), '2026-11-01T01:30:00-05:00',
   'in an overlap the abbreviation picks the reading');
is(sp('2026-11-01 01:30 EDT', '%Y-%m-%d %H:%M %Z', zone => 'America/New_York'), '2026-11-01T01:30:00-04:00', 'either one');
is(sp('2026 288', '%Y %j'), '2026-10-15T00:00:00Z', '%j');
is(sp('2026-10-15   09:00', '%Y-%m-%d %H:%M'), '2026-10-15T09:00:00Z', 'white space matches any white space');
is(sp('100%', '%Y%%'), '0100-01-01T00:00:00Z', '%%');
like(sp('2026-10-15 junk', '%Y-%m-%d'), qr/at offset 10: text was left over/, 'text left over');
like(sp('2026/10/15', '%Y-%m-%d'), qr/at offset 4: the text does not match the pattern/, 'text that does not match');
like(sp('2026-10-15', '%Y-%m-%d %Q'), qr/cannot be read/, 'a conversion it cannot read');

# CLDR patterns.
sub pc { my $t = eval { $K->parse_cldr(@_) }; defined $t ? "$t" : "died: $@" }
is(pc('Thursday, 15 October 2026', 'EEEE, d MMMM y'), '2026-10-15T00:00:00Z', 'a CLDR pattern');
is(pc('Oct 15, 2026, 9:05:07 PM', 'MMM d, y, h:mm:ss a'), '2026-10-15T21:05:07Z', 'with a time');
is(pc("Oct 15, 2026, 9:05:07\x{202F}PM", "MMM d, y, h:mm:ss\x{202F}a"), '2026-10-15T21:05:07Z', 'CLDR\'s narrow no-break space');
is(pc("Oct 15, 2026, 9:05:07 PM", "MMM d, y, h:mm:ss\x{202F}a"), '2026-10-15T21:05:07Z', 'which a plain space matches');
is(pc('20261015213005', 'yyyyMMddHHmmss'), '2026-10-15T21:30:05Z', 'fields with nothing between them take their widths');
is(pc("9 o'clock PM, 2026-10-15", "h 'o''clock' a, y-MM-dd"), '2026-10-15T21:00:00Z', 'quoted text');
is(pc('44 BC', 'y G'), '-000043-01-01T00:00:00Z', 'an era: 44 BC is the year -43');
is(pc('2026-10-15T21:05:07.123-04:00', "y-MM-dd'T'HH:mm:ss.SSSXXX"), '2026-10-15T21:05:07.123-04:00', 'an offset');
is(pc('2026-10-15 21:05 GMT+05:30', 'y-MM-dd HH:mm ZZZZ'), '2026-10-15T21:05:00+05:30', 'a localised GMT offset');
is(pc('2026-10-15 21:05 America/New_York', 'y-MM-dd HH:mm VV'), '2026-10-15T21:05:00-04:00', 'a zone\'s name');
{
    srand(22);
    my ($n, $bad) = (0, 0);
    for (1 .. 1000) {
        my $t = $K->from_epoch(int(rand(3e9)) + 100_000_000, zone => 'America/New_York');
        for my $p ('EEEE, MMMM d, y h:mm:ss a XXX', 'yyyy-MM-dd HH:mm:ss ZZZZ', 'd MMM y HH:mm:ss xxx', 'y-DDD HH:mm:ss Z') {
            my $s = $t->format($p);
            my $back = eval { $K->parse_cldr($s, $p) };
            $n++;
            $bad++, diag("'$p' wrote '$s', read " . ($back // "nothing: $@")) unless $back && $back == $t;
        }
    }
    is($bad, 0, "$n values written by format read back by parse_cldr");
}

ok(!defined $K->try_strptime('nonsense', '%Y'), 'try_strptime gives undef');
ok(!defined $K->try_parse_cldr('nonsense', 'y'), 'try_parse_cldr gives undef');
ok(defined $K->try_strptime('2026', '%Y'), 'and a value when it can');

done_testing;
