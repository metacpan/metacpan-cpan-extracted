use strict;
use warnings;
use Test::More tests => 6;
use Date::Parse qw(strptime);

# RT#106105: Date::Parse inconsistent year handling for years before 1901
# strptime() must return year as offset from 1900 consistently, regardless of
# whether the year is before or after 1900.  Previously, years <= 1900 were
# returned as the full 4-digit year rather than (year - 1900).
{
    # 1901: already worked — year=1, century=19
    my @t1901 = strptime('1 Jan 1901 12:00');
    is($t1901[5], 1,  "RT#106105: strptime year field is 1 for 1901 (offset from 1900)");
    is($t1901[7], 19, "RT#106105: strptime century field is 19 for 1901");

    # 1900: boundary — year=0, century=19
    my @t1900 = strptime('1 Jan 1900 12:00');
    is($t1900[5], 0,  "RT#106105: strptime year field is 0 for 1900 (offset from 1900)");
    is($t1900[7], 19, "RT#106105: strptime century field is 19 for 1900");

    # 1899: previously broken — returned 1899 instead of -1
    my @t1899 = strptime('1 Jan 1899 12:00');
    is($t1899[5], -1, "RT#106105: strptime year field is -1 for 1899 (offset from 1900)");
    is($t1899[7], 18, "RT#106105: strptime century field is 18 for 1899");
}
