use strict;
use warnings;
use Test::More tests => 3;
use Date::Parse qw(strptime str2time);

# GH#12 / RT#84075: Date::Parse::str2time maps date in 1963 to 2063
# Root cause: str2time passed a 2-digit year to timegm, triggering its 50-year
# sliding window.  The fix: strptime extracts the century and returns year as
# offset-from-1900; str2time reconstructs the full 4-digit year before calling
# timegm, bypassing the windowing entirely.
{
    my $this_year = 1900 + (gmtime(time))[5];
    my $target_year = $this_year - 50;
    my $date = "$target_year-01-01 00:00:00 UTC";
    my $time = str2time($date);
    my $year_parsed_as = 1900 + (gmtime($time))[5];
    is($year_parsed_as, $target_year, "GH#12: year $target_year not mapped to future");

    # Canonical example from the original bug report (year 1963)
    my $t1963 = str2time("1963-12-31 23:59:59 UTC");
    my $got1963 = 1900 + (gmtime($t1963))[5];
    is($got1963, 1963, "GH#12: 1963-12-31 not mapped to 2063");

    # strptime must capture the century for 4-digit years
    my @t = strptime("1963-12-31 23:59:59 UTC");
    is($t[7], 19, "GH#12: strptime century field is 19 for 1963");
}
