use strict;
use warnings;
use Test::More tests => 27;
use Date::Parse qw(strptime str2time);

# Tests for strptime() with ISO 8601 dates (GitHub issue #44)
#
# strptime() returns: ($ss, $mm, $hh, $day, $month, $year, $zone, $century)
#
# The return format follows Perl's localtime/gmtime convention:
#   $month  : 0-indexed (0=January, 1=February, ..., 11=December)
#   $year   : years since 1900 (e.g. 2015 => 115, 1995 => 95)
#   $century: defined only when a 4-digit year was parsed;
#             the full year = $year + 1900
#   $zone   : timezone offset in seconds from UTC, or undef if not specified

# --- Basic ISO 8601: YYYY-MM-DDTHH:MM:SS ---
{
    my @t = strptime("2015-01-01T08:51:00");
    ok(defined $t[0], "ss defined");
    cmp_ok($t[0]+0, '==', 0,   "ss=0");
    cmp_ok($t[1]+0, '==', 51,  "mm=51");
    cmp_ok($t[2]+0, '==', 8,   "hh=8");
    cmp_ok($t[3]+0, '==', 1,   "day=1");
    cmp_ok($t[4]+0, '==', 0,   "month=0 (January is 0-indexed)");
    cmp_ok($t[5]+0, '==', 115, "year=115 (2015-1900, following localtime convention)");
    ok(!defined $t[6], "zone=undef (no timezone in input)");
    cmp_ok($t[7]+0, '==', 20,  "century=20");
}

# --- ISO 8601 with fractional seconds ---
{
    my @t = strptime("1995-01-24T09:08:17.1823213");
    cmp_ok($t[3]+0, '==', 24,  "day=24");
    cmp_ok($t[4]+0, '==', 0,   "month=0 (January)");
    cmp_ok($t[5]+0, '==', 95,  "year=95 (1995-1900)");
    cmp_ok($t[2]+0, '==', 9,   "hh=9");
    cmp_ok($t[1]+0, '==', 8,   "mm=8");
    cmp_ok(abs($t[0] - 17.1823213), '<', 0.000001, "ss=17.1823213 (fractional seconds preserved)");
    cmp_ok($t[7]+0, '==', 19,  "century=19");
}

# --- ISO 8601 with Z (UTC) ---
{
    my @t = strptime("2015-03-15T12:00:00Z");
    cmp_ok($t[4]+0, '==', 2,   "month=2 (March is index 2)");
    cmp_ok($t[3]+0, '==', 15,  "day=15");
    cmp_ok($t[6]+0, '==', 0,   "zone=0 (UTC)");
}

# --- The full year can be recovered as: $year + 1900 ---
{
    my @t = strptime("2015-01-01T08:51:00");
    my $full_year = $t[5] + 1900;
    is($full_year, 2015, "full year = year + 1900 = 2015");
}

# --- str2time() correctly converts ISO 8601 to Unix timestamp ---
{
    my $ts = str2time("2015-01-01T08:51:00Z");
    ok(defined $ts, "str2time parses ISO 8601 with Z");
    is($ts, 1420102260, "str2time returns correct Unix timestamp");
}

# --- December: month index 11 ---
{
    my @t = strptime("2015-12-31T23:59:59");
    cmp_ok($t[4]+0, '==', 11,  "month=11 (December is 0-indexed 11)");
    cmp_ok($t[3]+0, '==', 31,  "day=31");
    cmp_ok($t[2]+0, '==', 23,  "hh=23");
}

# --- Colon as date separator (non-standard, but accepted by the parser) ---
{
    my @t = strptime("1995:01:24T09:08:17");
    cmp_ok($t[4]+0, '==', 0,  "colon-separated: month=0 (January)");
    cmp_ok($t[3]+0, '==', 24, "colon-separated: day=24");
}
