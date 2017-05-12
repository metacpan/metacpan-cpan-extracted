use strict;
use warnings;

use Test::More tests => 2;

use Weather::Underground::StationHistory qw{ generate_single_day_station_history_url };


# TEST
is(
    generate_single_day_station_history_url('KILCHICA42', 2006, 10, 27),
    'http://www.wunderground.com/weatherstation/WXDailyHistory.asp?ID=KILCHICA42&year=2006&month=10&day=27&graphspan=day&format=1',
    'should generate the proper URL to retrieve data for a single day for a single weather station with an alphanumeric identifier.'
);

# TEST
is(
    generate_single_day_station_history_url(93265, 1999, 7, 3),
    'http://www.wunderground.com/weatherstation/WXDailyHistory.asp?ID=93265&year=1999&month=7&day=3&graphspan=day&format=1',
    'should generate the proper URL to retrieve data for a single day for a single weather station with a numeric identifier.'
);


# setup vim: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup vim: set shiftwidth=4 shiftround textwidth=0 nowrap autoindent :
# setup vim: set foldmethod=indent foldlevel=0 :
