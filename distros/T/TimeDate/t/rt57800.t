use strict;
use warnings;
use Test::More tests => 4;
use Date::Parse qw(str2time);

# RT#57800 (GH#3): str2time fails on numeric m/d/yyyy dates before 1970
# str2time('5/1/1960') was returning undef with "Day too big" errors on
# 32-bit systems. Root cause: strptime extracts the 2-digit year (60) and
# stores century (19) separately. str2time must reconstruct the full 4-digit
# year before calling Time::Local to avoid the 2-digit year windowing heuristic
# mapping year 60 to 2060 instead of 1960.
{
    my @cases = (
        [ '5/1/1960',   1960,  5, 1, "m/d/yyyy May 1 1960" ],
        [ '1/5/1960',   1960,  1, 5, "m/d/yyyy Jan 5 1960" ],
        [ '12/31/1960', 1960, 12, 31, "m/d/yyyy Dec 31 1960" ],
        [ '5/1/1901',   1901,  5, 1,  "m/d/yyyy May 1 1901" ],
    );

    for my $c (@cases) {
        my ($date, $expected_year, $expected_mon, $expected_day, $desc) = @$c;

      SKIP: {
            skip "pre-1970 dates on Win32", 1 if $^O eq 'MSWin32';

            my $t = str2time($date);
            if (!defined $t) {
                fail("RT#57800: str2time('$date') returned undef");
                next;
            }
            my @gm = gmtime($t);
            my $got_year = 1900 + $gm[5];
            is($got_year, $expected_year, "RT#57800: $desc parses to year $expected_year");
        }
    }
}
