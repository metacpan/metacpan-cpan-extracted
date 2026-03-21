use strict;
use warnings;
use Test::More;
use Date::Parse qw(str2time strptime);
use Date::Language;

# --- Undef / empty / garbage inputs ---
ok(!defined str2time(undef),           "str2time(undef) returns undef");
ok(!defined str2time(""),              "str2time('') returns undef");
ok(!defined str2time("garbage"),       "str2time('garbage') returns undef");
ok(!defined str2time("not a date at all"), "str2time('not a date at all') returns undef");

# --- ISO 8601 variants ---
{
    my $t1 = str2time("2002-07-22T10:00:00Z");
    ok(defined $t1, "ISO 8601 with T separator and Z");
    is($t1, 1027332000, "ISO 8601 basic format parses correctly");

    my $t2 = str2time("2002-07-22 10:00:00Z");
    is($t2, 1027332000, "ISO 8601 with space separator and Z");

    my $t3 = str2time("20020722T100000Z");
    is($t3, 1027332000, "ISO 8601 compact format");

    my $t4 = str2time("2001-02-26T13:44:12-0700");
    is($t4, 983220252, "ISO 8601 with negative offset");

    my $t5 = str2time("2002-11-07T23:31:49-05:00");
    is($t5, 1036729909, "RFC 3339 with colon in offset");
}

# --- AM/PM parsing ---
{
    my $base = str2time("Jul 13 1999 13:23:00 GMT");
    is(str2time("Jul 13 1999 1:23P GMT"),    $base, "1:23P parses as PM");
    is(str2time("Jul 13 1999 1:23P.M GMT"),  $base, "1:23P.M parses as PM");
    is(str2time("Jul 13 1999 1:23P.M. GMT"), $base, "1:23P.M. parses as PM");

    my $am = str2time("92/01/02 12:01 AM");
    my $pm = str2time("92/01/02 12:01 PM");
    ok(defined $am && defined $pm, "AM/PM dates parse");
    cmp_ok($pm - $am, '==', 12 * 3600, "PM is 12 hours after AM");
}

# --- Fractional seconds ---
{
    my $t = str2time("2003-02-17T08:14:07.198189+0000");
    ok(defined $t, "fractional seconds parse");
    cmp_ok(abs($t - 1045469647.198189), '<', 0.001, "fractional seconds preserved");

    my $t2 = str2time("1995-01-24T09:08:17.1823213");
    ok(defined $t2, "high-precision fractional seconds parse");
}

# --- Apache-style dates ---
{
    my $t = str2time("07/Nov/2000:16:45:56 +0100");
    is($t, 973611956, "Apache log date format");
}

# --- RFC 2822 / email dates ---
{
    my $t = str2time("Wed, 9 Nov 1994 09:50:32 -0500 (EST)");
    is($t, 784392632, "RFC 2822 date with comment");

    my $t2 = str2time("Sat, 19 Nov 1994 16:59:14 +0100");
    is($t2, 785260754, "RFC 2822 date with positive offset");
}

# --- Date::Language error handling ---
{
    eval { Date::Language->new('NonexistentLanguage') };
    ok($@, "Date::Language->new with invalid language dies");

    my $fr = Date::Language->new('French');
    ok(defined $fr, "Date::Language->new('French') succeeds");

    my $ts = $fr->str2time('15 janvier 2010');
    ok(defined $ts, "French 'janvier' parses");
}

# --- French month parsing ---
{
    my $fr = Date::Language->new('French');
    my @months = (
        ['janvier',  1],
        ['mars',     3],
        ['juin',     6],
        ['octobre', 10],
        ['novembre', 11],
    );
    for my $pair (@months) {
        my ($month_name, $month_num) = @$pair;
        my $ts = $fr->str2time("15 $month_name 2010");
        if (defined $ts) {
            my @lt = localtime($ts);
            is($lt[4] + 1, $month_num, "French '$month_name' -> month $month_num");
        }
        else {
            fail("French '$month_name' failed to parse");
        }
    }
}

# --- Two-digit year handling ---
# Two-digit years: 69-99 -> 1969-1999, 0-68 -> 2000-2068 (POSIX convention)
{
    my $t = str2time("16 Oct 09");
    ok(defined $t, "two-digit year '09' parses");
    cmp_ok($t, '>=', 0, "two-digit year '09' gives non-negative time");
    my @gm = gmtime($t);
    is($gm[5] + 1900, 2009, "two-digit year '09' maps to 2009");
}

# --- Two-digit years for 1970s/1980s dates (GH issue #47) ---
{
    my $t74 = str2time("01 Jan 74 00:00:00 GMT");
    ok(defined $t74, "two-digit year '74' parses");
    is($t74, 126230400, "two-digit year '74' gives 1974-01-01 not 2074");

    my $t73 = str2time("15 Jun 73 12:00:00 GMT");
    ok(defined $t73, "two-digit year '73' parses");
    my @gm73 = gmtime($t73);
    is($gm73[5] + 1900, 1973, "two-digit year '73' maps to 1973");

    my $t72 = str2time("01 Jan 72 00:00:00 GMT");
    ok(defined $t72, "two-digit year '72' parses");
    my @gm72 = gmtime($t72);
    is($gm72[5] + 1900, 1972, "two-digit year '72' maps to 1972");

    # Boundary: 69 -> 1969, 68 -> 2068
    my $t69 = str2time("01 Jan 69 00:00:00 GMT");
    ok(defined $t69, "two-digit year '69' parses");
    my @gm69 = gmtime($t69);
    is($gm69[5] + 1900, 1969, "two-digit year '69' maps to 1969 (boundary)");
}

# --- Time-only formats ---
{
    my $t = str2time("10:00:00Z");
    ok(defined $t, "time-only with Z parses");

    my $t2 = str2time("10:00:00");
    ok(defined $t2, "time-only without zone parses");

    my $t3 = str2time("10:00");
    ok(defined $t3, "time-only HH:MM parses");
}

# --- Various date separator styles ---
{
    my $t1 = str2time("21 dec 17:05");
    my $t2 = str2time("21-dec 17:05");
    my $t3 = str2time("21/dec 17:05");
    ok(defined $t1, "space-separated day month");
    is($t1, $t2, "dash separator matches space separator");
    is($t1, $t3, "slash separator matches space separator");
}

# --- Boost C++ timestamp format ---
{
    my $t = str2time("2024-May-15 14:30:00.123456");
    ok(defined $t, "boost format YYYY-Mon-DD HH:MM:SS.f parses");
}

# --- Leap day (Feb 29) handling ---
# When only a year is given, str2time fills in the current month/day.
# On Feb 29 the year must be a leap year or str2time returns undef.
# See: https://github.com/atoomic/perl-TimeDate/issues/28
{
    # Explicit Feb 29 on a leap year must succeed
    my $t1 = str2time("29 Feb 2000 10:02:18 GMT");
    ok(defined $t1,      "Feb 29 of leap year 2000 parses");
    is($t1, 951818538,   "Feb 29 2000 10:02:18 GMT matches expected epoch");

    # Explicit Feb 29 on a non-leap year must fail
    my $t2 = str2time("29 Feb 1999 10:02:18 GMT");
    ok(!defined $t2,     "Feb 29 of non-leap year 1999 returns undef");
}

# --- Comma as decimal separator in fractional seconds (ISO 8601) ---
{
    my $dot = str2time("2016-01-28 23:27:13.995 UTC");
    my $comma = str2time("2016-01-28 23:27:13,995 UTC");
    ok(defined $dot,   "dot decimal fractional seconds parse");
    ok(defined $comma, "comma decimal fractional seconds parse");
    cmp_ok(abs($dot - $comma), '<', 0.01,
        "comma decimal gives same result as dot decimal");

    my $t1 = str2time("2016-01-28 23:27:13,995 UTC");
    my $t2 = str2time("2016-01-28 23:27:13,996 UTC");
    cmp_ok($t2, '>', $t1,
        "comma decimal: ,996 is later than ,995");
    cmp_ok(abs($t2 - $t1 - 0.001), '<', 0.0001,
        "comma decimal: difference is ~1ms");

    # RFC 2822 commas still work
    my $rfc = str2time("Wed, 16 Jun 94 07:29:35 CST");
    is($rfc, 771773375, "RFC 2822 comma after day name still works");
}


# --- Year inference for dates without an explicit year (GH #46) ---
# When no year is given, str2time should assume the most recent occurrence:
# a date in the future (month > now, OR same month but day > today) gets
# previous year; a date in the past (or today) gets current year.
{
    my @lt = localtime();
    my ($cur_day, $cur_month, $cur_year) = @lt[3, 4, 5];
    $cur_year += 1900;

    my @mon_names = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);

    # A future month (strictly > current month): should infer previous year.
    if ($cur_month < 11) {
        my $future_mon = $mon_names[$cur_month + 1];
        my $t = str2time("$future_mon 4 01:04:16");
        ok(defined $t, "future month '$future_mon 4': parses");
        my @res = localtime($t);
        is($res[5] + 1900, $cur_year - 1,
            "future month ($future_mon) → previous year (GH#46)");
    }

    # A past month (strictly < current month): should infer current year.
    if ($cur_month > 0) {
        my $past_mon = $mon_names[$cur_month - 1];
        my $t = str2time("$past_mon 4 01:04:16");
        ok(defined $t, "past month '$past_mon 4': parses");
        my @res = localtime($t);
        is($res[5] + 1900, $cur_year,
            "past month ($past_mon) → current year (GH#46)");
    }

    # Same month, day strictly in the future → previous year.
    if ($cur_day <= 27) {
        my $future_day = $cur_day + 1;
        my $mon = $mon_names[$cur_month];
        my $t = str2time(sprintf("%s %d 01:04:16", $mon, $future_day));
        ok(defined $t, "future day same month '$mon $future_day': parses");
        my @res = localtime($t);
        is($res[5] + 1900, $cur_year - 1,
            "same month, future day ($mon $future_day) → previous year (GH#46)");
    }

    # Same month, day strictly in the past → current year.
    if ($cur_day >= 2) {
        my $past_day = $cur_day - 1;
        my $mon = $mon_names[$cur_month];
        my $t = str2time(sprintf("%s %d 01:04:16", $mon, $past_day));
        ok(defined $t, "past day same month '$mon $past_day': parses");
        my @res = localtime($t);
        is($res[5] + 1900, $cur_year,
            "same month, past day ($mon $past_day) → current year (GH#46)");
    }
}

done_testing;
