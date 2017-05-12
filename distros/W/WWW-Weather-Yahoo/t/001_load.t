# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More ;

BEGIN {
    use_ok('WWW::Weather::Yahoo');
    use_ok('WWW::Mechanize');
    use_ok('XML::XPath');
#   use_ok('XML::XPath::XMLParser');
}

my $weather = WWW::Weather::Yahoo->new( 'São Paulo, SP', 'c' );
isa_ok( $weather, 'WWW::Weather::Yahoo' );
is( $weather->{_weather}{unit_temperature},
    'C', 'Unit Temperature is Celcius, as expected.' );
is( $weather->{_weather}{location_country},
    'Brazil', 'Country for São Paulo should be Brazil.' );
is( valid_weather_hash_v1( $weather), 1, 'is valid weather.. are the hash keys filled as expected' );

$weather = WWW::Weather::Yahoo->new( 'Miami, FL', 'f' );
is( $weather->{_weather}{unit_temperature},
    'F', 'Unit Temperature is Celcius, as expected.' );
is(
    $weather->{_weather}{location_country},
    'United States',
    'Country for Miami, FL should be United States'
);
is( valid_weather_hash_v1( $weather), 1, 'is valid weather.. are the hash keys filled as expected' );

$weather = WWW::Weather::Yahoo->new('São Paulo, SP');
is( $weather->{_weather}{unit_temperature},
    'C', 'Default Unit Temperature is Celcius, as expected.' );
is( $weather->{_weather}{location_country},
    'Brazil', 'Country for São Paulo should be Brazil.' );
is( valid_weather_hash_v1( $weather), 1, 'is valid weather.. are the hash keys filled as expected' );


#tests by WOEID
$weather = WWW::Weather::Yahoo->new(455827, 'c');
is( $weather->{_weather}{unit_temperature},
    'C', 'Default Unit Temperature is Celcius, as expected.' );
is( $weather->{_weather}{location_country},
    'Brazil', 'Country for São Paulo should be Brazil.' );
is( valid_weather_hash_v1( $weather), 1, 'is valid weather.. are the hash keys filled as expected' );



#   $weather = WWW::Weather::Yahoo->new('some invalid city');
#   is( $weather, undef,
#   'Invalid city name or city not found, try looking up your city name at http://weather.yahoo.com/ and use the correct city name.'
#   );
#   is( valid_weather_hash_v1( $weather), 0, 'is valid weather.. are the hash keys filled as expected' );



#   $weather = WWW::Weather::Yahoo->new( );
#   is( $weather, undef,
#   'Invalid city name or city not found, try looking up your city name at http://weather.yahoo.com/ and use the correct city name.'
#   );
#   is( valid_weather_hash_v1( $weather), 0, 'is valid weather.. are the hash keys filled as expected' );


sub valid_weather_hash_v1 {
    my ( $weather ) = @_;
    return 0 if ! exists  $weather->{ _weather }{location_city};
    return 0 if ! exists  $weather->{ _weather }{location_region};       
    return 0 if ! exists  $weather->{ _weather }{location_country};
    return 0 if ! exists  $weather->{ _weather }{unit_temperature};
    return 0 if ! exists  $weather->{ _weather }{unit_distance};
    return 0 if ! exists  $weather->{ _weather }{unit_pressure};
    return 0 if ! exists  $weather->{ _weather }{unit_speed};
    return 0 if ! exists  $weather->{ _weather }{wind_chill};
    return 0 if ! exists  $weather->{ _weather }{wind_direction};
    return 0 if ! exists  $weather->{ _weather }{wind_speed};
    return 0 if ! exists  $weather->{ _weather }{atmosphere_humidity};
    return 0 if ! exists  $weather->{ _weather }{atmosphere_visibility};
    return 0 if ! exists  $weather->{ _weather }{atmosphere_pressure};
    return 0 if ! exists  $weather->{ _weather }{atmosphere_rising};
    return 0 if ! exists  $weather->{ _weather }{astronomy_sunrise};
    return 0 if ! exists  $weather->{ _weather }{astronomy_sunset};
    return 0 if ! exists  $weather->{ _weather }{location_lat};
    return 0 if ! exists  $weather->{ _weather }{location_lng};
    return 0 if ! exists  $weather->{ _weather }{condition_text};
    return 0 if ! exists  $weather->{ _weather }{condition_code};
    return 0 if ! exists  $weather->{ _weather }{condition_temp};
    return 0 if ! exists  $weather->{ _weather }{condition_date};
    return 0 if ! exists  $weather->{ _weather }{condition_img_src};
    return 0 if ! exists  $weather->{ _weather }{forecast_tomorrow_day};
    return 0 if ! exists  $weather->{ _weather }{forecast_tomorrow_date};
    return 0 if ! exists  $weather->{ _weather }{forecast_tomorrow_low};
    return 0 if ! exists  $weather->{ _weather }{forecast_tomorrow_high};
    return 0 if ! exists  $weather->{ _weather }{forecast_tomorrow_text};
    return 0 if ! exists  $weather->{ _weather }{forecast_tomorrow_code};
    return 1;
}

done_testing;
