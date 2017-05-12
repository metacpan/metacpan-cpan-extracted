use Test::More tests => 11;

use warnings;
use strict;

use Weather::Bug;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::Weather::Bug;
use TestHelper;

my $wxbug = Test::Weather::Bug->new( -key => 'FAKELICENSEKEY' );

my $weather = $wxbug->get_live_compact_weather( 'HST02', '77035' );

isa_ok( $weather, 'Weather::Bug::CompactWeather' );
is( $weather->station()->id(), 'HST02', 'Station has correct id.' );
is( $weather->station()->location()->city(), 'Houston', 'City is correct.' );
is( $weather->station()->location()->state(), 'TX', 'State is correct.' );
is( $weather->station()->location()->zipcode(), 77035, 'Zip is correct.' );
temperature_ok( $weather->temp(), 'temp', { f => 83.8, is_SI => 0 } );
quantity_ok( $weather->rain_today(), 'rain_today', { null => 1, units => 'in' } );
quantity_ok( $weather->wind_speed(), 'wind_speed', { value => 4, units => 'mph' } );
is( $weather->wind_dir(), 'S', 'Wind direction is correct' );
quantity_ok( $weather->gust_speed(), 'gust_speed', { value => 18, units => 'mph' } );
is( $weather->gust_dir(), 'SE', 'Gust direction is correct' );

