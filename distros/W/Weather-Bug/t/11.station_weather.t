use Test::More tests => 42;

use warnings;
use strict;

use Weather::Bug;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::Weather::Bug;
use TestHelper;

my $wxbug = Test::Weather::Bug->new( -key => 'FAKELICENSEKEY' );

my $station = ($wxbug->list_stations( 77096 ))[0];

can_ok( $station, 'get_live_weather' );

my $weather = $station->get_live_weather();

isa_ok( $weather, 'Weather::Bug::Weather' );
is( $station, $weather->station(), 'Station is the same.' );
datetime_ok( $weather->date(), 'Date',
        { ymd => '2008-07-18', hms => '21:29:01', tz => '-0500'} );
temperature_ok( $weather->aux_temp(), 'aux_temp', { f => -100, is_SI => 0 } );
temperature_ok( $weather->aux_temp_rate(), 'aux_temp_rate', { f => -0.3, is_SI => 0 } );
temperature_ok( $weather->dew_point(), 'dew_point', { f => 73, is_SI => 0 } );

quantity_ok( $weather->elevation(), 'elevation', {value=>59, units=>'ft'} );
temperature_ok( $weather->feels_like(), 'feels_like', { f => 90, is_SI => 0 } );

datetime_ok( $weather->gust_time(), 'Gust time',
        { ymd => '2008-07-18', hms => '21:29:01', tz => '-0500'} );
quantity_ok( $weather->gust_speed(), 'gust_speed', {value=>18, units=>'mph'} );
is( $weather->gust_dir(), 'SE', 'gust_dir is correct.' );

quantity_ok( $weather->humidity(), 'humidity', {value=>68, units=>'%'} );
quantity_ok( $weather->humidity_high(), 'humidity_high', {value=>92.1, units=>'%'} );
quantity_ok( $weather->humidity_low(), 'humidity_low', {value=>39.4, units=>'%'} );
is( $weather->humidity_rate(), '+5.7', 'humidity_rate' );

temperature_ok( $weather->indoor_temp(), 'indoor_temp', { f => 84, is_SI => 0 } );
temperature_ok( $weather->indoor_temp_rate(), 'indoor_temp_rate', { f => '0.0', is_SI => 0 } );

is( $weather->light(), 0, 'light is correct' );
is( $weather->light_rate(), '+0.0', 'light_rate is correct' );

is( $weather->moon_phase(), 100, 'moon_phase is correct' );
is( $weather->moon_phase_img(), 'http://api.wxbug.net/images/moonphase/mphase14.gif', 'moon_phase_img is correct' );

quantity_ok( $weather->pressure(), 'pressure', {value=>29.95, units=>'in'} );
quantity_ok( $weather->pressure_high(), 'pressure_high', {value=>30.02, units=>'in'} );
quantity_ok( $weather->pressure_low(), 'pressure_low', {value=>29.93, units=>'in'} );
is( $weather->pressure_rate(), '+0.00', 'pressure_rate' );

quantity_ok( $weather->rain_month(), 'rain_month', {null=>1,units=>'in'} );
quantity_ok( $weather->rain_rate(), 'rain_rate', {null=>1,units=>'in/h'} );
quantity_ok( $weather->rain_rate_max(), 'rain_rate_max', {null=>1,units=>'in/h'} );
quantity_ok( $weather->rain_today(), 'rain_today', {null=>1,units=>'in'} );
quantity_ok( $weather->rain_year(), 'rain_year', {null=>1,units=>'in'} );

temperature_ok( $weather->temp(), 'temp', { f => 83.9, is_SI => 0 } );
temperature_ok( $weather->temp_high(), 'temp_high', { f => 96, is_SI => 0 } );
temperature_ok( $weather->temp_low(), 'temp_low', { f => 75, is_SI => 0 } );
temperature_ok( $weather->temp_rate(), 'temp_rate', { f => -1.3, is_SI => 0 } );

datetime_ok( $weather->sunrise(), 'Sunrise time',
        { ymd => '2008-07-18', hms => '06:33:46', tz => 'floating'} );
datetime_ok( $weather->sunset(), 'Sunset time',
        { ymd => '2008-07-18', hms => '20:22:12', tz => 'floating'} );

temperature_ok( $weather->wet_bulb(), 'wet_bulb', { f => 75.542, is_SI => 0 } );

quantity_ok( $weather->wind_speed(), 'wind_speed', {value=>2, units=>'mph'} );
quantity_ok( $weather->wind_speed_avg(), 'wind_speed_avg', {value=>2, units=>'mph'} );
is( $weather->wind_dir(), 'S', 'wind_dir is correct.' );
is( $weather->wind_dir_avg(), 'SSE', 'wind_dir_avg is correct.' );

