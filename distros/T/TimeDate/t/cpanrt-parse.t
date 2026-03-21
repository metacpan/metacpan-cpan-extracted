use strict;
use warnings;
use Test::More tests => 26;
use Date::Parse qw(strptime str2time);

# RT#48164: Date::Parse unable to set seconds correctly
{
    for my $str ("2008.11.30 22:35 CET", "2008-11-30 22:35 CET") {
        my @t = strptime($str);
        my $t = join ":", map { defined($_) ? $_ : "-" } @t;
        is($t, "-:35:22:30:10:108:3600:20", "RT#48164: seconds parsing for '$str'");
    }
}

# RT#51664: Change in str2time behaviour between 1.16 and 1.19
{
    ok(str2time('16 Oct 09') >= 0, "RT#51664: '16 Oct 09' parses to non-negative time");
}

# RT#84075: Date::Parse::str2time maps date in 1963 to 2063
{
    my $this_year = 1900 + (gmtime(time))[5];
    my $target_year = $this_year - 50;
    my $date = "$target_year-01-01 00:00:00 UTC";
    my $time = str2time($date);
    my $year_parsed_as = 1900 + (gmtime($time))[5];
    is($year_parsed_as, $target_year, "RT#84075: year $target_year not mapped to future");
}

# RT#70650: Date::Parse should not parse ludicrous strings like bare numbers
{
    ok(!defined str2time('1'),      "RT#70650: str2time('1') returns undef");
    ok(!defined str2time('+01'),    "RT#70650: str2time('+01') returns undef");
    ok(!defined str2time('+0500'),  "RT#70650: str2time('+0500') returns undef");
}

# RT#53413 / RT#105031 (GH#17): Date::Parse mangling 4-digit year dates
# str2time() must not map 4-digit pre-1970 years to future dates.
# The root cause: strptime() extracts a 2-digit year (subtracting 1900 from
# the 4-digit value) and stores the century separately. str2time() must
# reconstruct the full 4-digit year before calling Time::Local, whose
# 2-digit-year windowing would otherwise map e.g. year 24 (from 1924) to 2024,
# or year 65 (from 1965) to 2065.
{
    my @cases = (
        [ "1924-01-15 00:00:00 UTC", 1924, "year 1924 does not map to 2024" ],
        [ "1963-06-16 00:00:00 UTC", 1963, "year 1963 does not map to 2063" ],
        [ "1965-12-31 00:00:00 UTC", 1965, "year 1965 does not map to 2065" ],
        [ "1966-01-01 00:00:00 UTC", 1966, "year 1966 does not map to future" ],
        [ "1901-12-17 00:00:00 UTC", 1901, "year 1901 parses correctly" ],
        [ "1935-01-24 00:00:00 UTC", 1935, "year 1935 does not map to future" ],
    );

    for my $c (@cases) {
        my ($date, $expected_year, $desc) = @$c;
        my $t = str2time($date);
        if (!defined $t) {
            fail("RT#53413: str2time('$date') returned undef");
            next;
        }
        my $parsed_year = 1900 + (gmtime($t))[5];
        is($parsed_year, $expected_year, "RT#53413: $desc");
    }

    # strptime() must return year as offset from 1900 with century captured separately
    my @t = strptime("1924-01-15 00:00:00 UTC");
    is($t[5], 24,  "RT#53413: strptime year field is 24 for 1924 (offset from 1900)");
    is($t[7], 19,  "RT#53413: strptime century field is 19 for 1924");
}

# RT#92611: str2time should pick the most recent occurrence when no year given.
# A future month means the most recent occurrence was last year.
{
    my @lt = localtime(time);
    my $cur_month = $lt[4];            # 0-11
    my $cur_year  = 1900 + $lt[5];
    my @months    = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);

  SKIP: {
        # December → January crosses a year boundary; the heuristic is ambiguous there.
        skip "RT#92611: skipping in December (year-boundary edge case)", 1
            if $cur_month == 11;

        my $future_month = $cur_month + 1;    # guaranteed valid (0-10 → 1-11)
        my $future_name  = $months[$future_month];
        my $t = str2time("15 $future_name");
        my $got_year = 1900 + (localtime($t))[5];
        is($got_year, $cur_year - 1,
            "RT#92611: '15 $future_name' with no year resolves to previous year (most recent occurrence)");
    }
}

# RT#53267 / GH#2: strptime('MONTH YEAR') puts year into $day
# 'December 2009' should give month=11, year=109 (2009-1900), day=undef
# not month=11, day=2009, year=undef
{
    my ($ss,$mm,$hh,$day,$month,$year,$zone) = strptime('December 2009');
    is($month, 11,  "RT#53267: 'December 2009' gives month=11 (December)");
    ok(!defined($day), "RT#53267: 'December 2009' gives day=undef (not 2009)");
    is($year,  109, "RT#53267: 'December 2009' gives year=109 (2009-1900)");

    # 4-digit year in same position
    ($ss,$mm,$hh,$day,$month,$year,$zone) = strptime('Jan 1995');
    is($month, 0,   "RT#53267: 'Jan 1995' gives month=0 (January)");
    ok(!defined($day), "RT#53267: 'Jan 1995' gives day=undef");
    is($year,  95,  "RT#53267: 'Jan 1995' gives year=95 (1995-1900)");

    # normal 'MONTH DAY' must still work
    ($ss,$mm,$hh,$day,$month,$year,$zone) = strptime('December 25');
    is($month, 11, "RT#53267: 'December 25' still gives month=11");
    is($day,   25, "RT#53267: 'December 25' still gives day=25");
}

# RT#125949: strptime returns negative month for certain inputs
{
    my @t = strptime("199001");
    my $month = $t[4];
    ok(!defined($month) || $month >= 0,
        "RT#125949: strptime('199001') month is not negative");

    my $t = str2time("199001");
    ok(!defined($t),
        "RT#125949: str2time('199001') returns undef for ambiguous 6-digit input");
}
