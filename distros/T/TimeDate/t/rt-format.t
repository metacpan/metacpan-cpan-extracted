use strict;
use warnings;
use Test::More tests => 2;
use Date::Format qw(time2str);

# RT#45067: Date::Format with %z gives wrong results for half-hour timezones
{
    for my $zone (qw(-0430 -0745)) {
        my $zone_str = time2str("%Z %z", time, $zone);
        is($zone_str, "$zone $zone", "RT#45067: half-hour timezone $zone");
    }
}
