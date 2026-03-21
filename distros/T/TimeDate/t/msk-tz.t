use strict;
use warnings;
use Test::More tests => 2;
use Date::Parse qw(str2time);
use Time::Zone;

# RT#81350: MSK (Moscow Standard Time) offset
# Russia was UTC+4 in 2011-2014 (permanent DST), but reverted to UTC+3 in October 2014.
# The correct current offset is UTC+3 = 10800 seconds.
{
    my $offset = tz_offset("MSK");
    is($offset, 10800, "RT#81350: tz_offset('MSK') returns 10800 (UTC+3)");

    my $time = str2time("2024-01-15 12:00:00 MSK");
    my $time_utc = str2time("2024-01-15 09:00:00 UTC");
    is($time, $time_utc, "RT#81350: MSK date parses to correct UTC equivalent");
}
