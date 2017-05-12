#!/usr/bin/env perl
#
use 5.006;
use strict;
use warnings FATAL => 'all';

use Test::More;

use DateTime::TimeZone;
use File::Slurp;
use FindBin;

use Weather::YR;

my $xml = File::Slurp::read_file( $FindBin::Bin . '/data/locationForecast.xml' );

my $yr = Weather::YR->new(
    xml => $xml,
    tz  => DateTime::TimeZone->new( name => 'Europe/Oslo' ),
);

my $now      = DateTime->new( year => 2014, month => 8, day => 15, hour => 8, minute => 30, second => 0 );
my $forecast = $yr->location_forecast;

is( scalar(@{$forecast->datapoints}), 83, 'Number of data points is OK.' );
is( $forecast->today->datapoints->[0]->from, '2014-08-15T11:00:00', 'From-date for "today" is OK.' );
is( $forecast->today->wind_direction->name, 'NW', 'Wind direction is OK.' );
is( $forecast->today->wind_direction->degrees, '297.0', 'Wind direction in degrees is OK.' );
is( $forecast->today->wind_speed->mps, '2.0', 'Wind speed is OK.' );
is( $forecast->today->humidity->percent, '71.3', 'Humidity is OK.' );
is( $forecast->today->pressure->hPa, '1007.7', 'Pressure is OK.' );
is( $forecast->today->cloudiness->percent, '38.5', 'Cloudiness is OK.' );
is( $forecast->today->fog->percent, '-0.0', 'Fog is OK.' );
is( $forecast->today->dew_point_temperature->celsius, '9.0', 'Dew point temperature is OK.' );

# The End
done_testing;
