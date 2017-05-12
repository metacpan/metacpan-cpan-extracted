use Test::More tests => 15;

use warnings;
use strict;

use Weather::Bug;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::Weather::Bug;

my $wxbug = Test::Weather::Bug->new( -key => 'FAKELICENSEKEY' );

my $station = ($wxbug->list_stations( 77096 ))[0];

can_ok( $station, 'get_live_compact_weather' );

my $weather = $station->get_live_compact_weather();

isa_ok( $weather, 'Weather::Bug::CompactWeather' );
is( $station, $weather->station(), 'Station is the same.' );
isa_ok( $weather->temp(), 'Weather::Bug::Temperature' );
isa_ok( $weather->rain_today(), 'Weather::Bug::Quantity' );
is( $weather->rain_today()->units(), 'in', 'Units for rain are correct.' );
ok( $weather->rain_today()->is_null(), 'No rain.' );
isa_ok( $weather->wind_speed(), 'Weather::Bug::Quantity' );
is( $weather->wind_speed()->value(), 4, 'Correct wind speed' );
is( $weather->wind_speed()->units(), 'mph', 'Units for wind speed are correct.' );
is( $weather->wind_dir(), 'S', 'Wind direction is correct' );
isa_ok( $weather->gust_speed(), 'Weather::Bug::Quantity' );
is( $weather->gust_speed()->value(), 18, 'Correct gust speed' );
is( $weather->gust_speed()->units(), 'mph', 'Units for gust speed are correct.' );
is( $weather->gust_dir(), 'SE', 'Gust direction is correct' );

