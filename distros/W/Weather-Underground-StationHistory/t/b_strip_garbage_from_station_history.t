use strict;
use warnings;

use Test::More tests => 2;

use Weather::Underground::StationHistory qw{ strip_garbage_from_station_history };

SKIP: {
    eval 'use Test::Differences;';

    skip( "because Test::Differences isn't installed.", Test::More->builder->expected_tests() )
        if $@;

    {
        my $original_data = <<'ORIGINAL_DATA';

Time,TemperatureF,DewpointF,PressureIn,WindDirection,WindDirectionDegrees,WindSpeedMPH,WindSpeedGustMPH,Humidity,HourlyPrecipIn,Conditions,Clouds,dailyrainin,SoftwareType<br>
<!-- 0.070:0 -->
ORIGINAL_DATA

        my $cleaned_data = <<'CLEANED_DATA';
Time,TemperatureF,DewpointF,PressureIn,WindDirection,WindDirectionDegrees,WindSpeedMPH,WindSpeedGustMPH,Humidity,HourlyPrecipIn,Conditions,Clouds,dailyrainin,SoftwareType
CLEANED_DATA

        # TEST
        eq_or_diff(
            strip_garbage_from_station_history($original_data),
            $cleaned_data,
            'Weather Underground output for a day with no data should have been stripped down to just the headers',
        );
    } # end anonymous block

    {
        my $original_data = <<'ORIGINAL_DATA';

Time,TemperatureF,DewpointF,PressureIn,WindDirection,WindDirectionDegrees,WindSpeedMPH,WindSpeedGustMPH,Humidity,HourlyPrecipIn,Conditions,Clouds,dailyrainin,SoftwareType<br>
2006-10-26 00:00:00,48.0,24.9,29.56,NE,51,0,4,40,0.00,,,,VWS V13.00,
<br>
2006-10-26 00:30:00,48.4,24.0,29.53,NE,40,0,5,38,0.00,,,,VWS V13.00,
<br>
2006-10-26 01:00:00,48.2,24.4,29.53,SE,137,0,3,39,0.00,,,,VWS V13.00,
<br>
2006-10-26 01:30:00,48.2,23.8,29.53,NNE,33,0,4,38,0.00,,,,VWS V13.00,
<br>
2006-10-26 02:00:00,48.4,24.0,29.53,ENE,68,0,4,38,0.00,,,,VWS V13.00,
<br>
2006-10-26 02:30:00,48.2,24.4,29.53,East,97,0,4,39,0.00,,,,VWS V13.00,
<br>
2006-10-26 03:00:00,47.8,24.1,29.53,ENE,57,0,4,39,0.00,,,,VWS V13.00,
<br>
<!-- 0.061:0 -->
ORIGINAL_DATA

        my $cleaned_data = <<'CLEANED_DATA';
Time,TemperatureF,DewpointF,PressureIn,WindDirection,WindDirectionDegrees,WindSpeedMPH,WindSpeedGustMPH,Humidity,HourlyPrecipIn,Conditions,Clouds,dailyrainin,SoftwareType
2006-10-26 00:00:00,48.0,24.9,29.56,NE,51,0,4,40,0.00,,,,VWS V13.00,
2006-10-26 00:30:00,48.4,24.0,29.53,NE,40,0,5,38,0.00,,,,VWS V13.00,
2006-10-26 01:00:00,48.2,24.4,29.53,SE,137,0,3,39,0.00,,,,VWS V13.00,
2006-10-26 01:30:00,48.2,23.8,29.53,NNE,33,0,4,38,0.00,,,,VWS V13.00,
2006-10-26 02:00:00,48.4,24.0,29.53,ENE,68,0,4,38,0.00,,,,VWS V13.00,
2006-10-26 02:30:00,48.2,24.4,29.53,East,97,0,4,39,0.00,,,,VWS V13.00,
2006-10-26 03:00:00,47.8,24.1,29.53,ENE,57,0,4,39,0.00,,,,VWS V13.00,
CLEANED_DATA

        # TEST
        eq_or_diff(
            strip_garbage_from_station_history($original_data),
            $cleaned_data,
            'pseudo-HTML should have been stripped from regular Weather Underground output',
        );
    } # end anonymous block
} # end SKIP

# setup vim: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup vim: set shiftwidth=4 shiftround textwidth=0 nowrap autoindent :
# setup vim: set foldmethod=indent foldlevel=0 :
