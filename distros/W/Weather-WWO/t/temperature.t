use strict;
use warnings;
use Test::More;
use Weather::WWO;

my $data;
my $location = '90230';
my $api_key  = 'fake';
my $wwo       = Weather::WWO->new(
    api_key           => $api_key,
    location          => $location,
    temperature_units => 'F',
    wind_units        => 'Miles',
);
isa_ok($wwo, 'Weather::WWO');
$wwo->data($data);
is(ref($wwo->data), 'HASH', 'data is a HashRef');
# Setting the data to something we've gotten from WWO before.
# Ideally one would put in a real api key and fetch some live data
my ( $highs, $lows ) = $wwo->forecast_temperatures;
my $winds = $wwo->winds;

my $highs_fixture = [ 58, 56, 56, 57, 59 ];
my $lows_fixture  = [ 56, 53, 52, 43, 41 ];
my $winds_fixture = [ 13, 6, 13, 15, 7 ];

is_deeply($highs, $highs_fixture, 'Highs');
is_deeply($lows,  $lows_fixture,  'Lows' );
is_deeply($winds, $winds_fixture, 'Winds');


done_testing();

sub BEGIN {
    $data = {
        current_condition => [
            {
                cloudcover       => 100,
                humidity         => 100,
                observation_time => "11:38 PM",
                precipMM         => "23.3",
                pressure         => 1011,
                temp_C           => 14,
                temp_F           => 57,
                visibility       => 5,
                weatherCode      => 308,
                weatherDesc      => [ { value => "Heavy rain" } ],
                weatherIconUrl   => [
                    {
                        value =>
                          "http://free.worldweatheronline.com/images/wsymbols01_png_64/wsymbol_0018_cloudy_with_heavy_rain.png"
                    }
                ],
                winddir16Point => "SSW",
                winddirDegree  => 204,
                windspeedKmph  => 18,
                windspeedMiles => 11
            }
        ],
        request => [
            {
                query => "Lat 34.00 and Lon -118.00",
                type  => "LatLon"
            }
        ],
        weather => [
            {
                date           => "2010-12-19",
                precipMM       => "180.1",
                tempMaxC       => 14,
                tempMaxF       => 58,
                tempMinC       => 13,
                tempMinF       => 56,
                weatherCode    => 308,
                weatherDesc    => [ { value => "Heavy rain" } ],
                weatherIconUrl => [
                    {
                        value =>
                          "http://free.worldweatheronline.com/images/wsymbols01_png_64/wsymbol_0018_cloudy_with_heavy_rain.png"
                    }
                ],
                winddir16Point => "SSW",
                winddirDegree  => 207,
                winddirection  => "SSW",
                windspeedKmph  => 21,
                windspeedMiles => 13
            },
            {
                date           => "2010-12-20",
                precipMM       => "57.5",
                tempMaxC       => 13,
                tempMaxF       => 56,
                tempMinC       => 12,
                tempMinF       => 53,
                weatherCode    => 302,
                weatherDesc    => [ { value => "Moderate rain" } ],
                weatherIconUrl => [
                    {
                        value =>
                          "http://free.worldweatheronline.com/images/wsymbols01_png_64/wsymbol_0018_cloudy_with_heavy_rain.png"
                    }
                ],
                winddir16Point => "WSW",
                winddirDegree  => 250,
                winddirection  => "WSW",
                windspeedKmph  => 10,
                windspeedMiles => 6
            },
            {
                date           => "2010-12-21",
                precipMM       => "81.5",
                tempMaxC       => 13,
                tempMaxF       => 56,
                tempMinC       => 11,
                tempMinF       => 52,
                weatherCode    => 302,
                weatherDesc    => [ { value => "Moderate rain" } ],
                weatherIconUrl => [
                    {
                        value =>
                          "http://free.worldweatheronline.com/images/wsymbols01_png_64/wsymbol_0018_cloudy_with_heavy_rain.png"
                    }
                ],
                winddir16Point => "E",
                winddirDegree  => 80,
                winddirection  => "E",
                windspeedKmph  => 21,
                windspeedMiles => 13
            },
            {
                date           => "2010-12-22",
                precipMM       => "132.1",
                tempMaxC       => 14,
                tempMaxF       => 57,
                tempMinC       => 6,
                tempMinF       => 43,
                weatherCode    => 359,
                weatherDesc    => [ { value => "Torrential rain shower" } ],
                weatherIconUrl => [
                    {
                        value =>
                          "http://free.worldweatheronline.com/images/wsymbols01_png_64/wsymbol_0018_cloudy_with_heavy_rain.png"
                    }
                ],
                winddir16Point => "S",
                winddirDegree  => 185,
                winddirection  => "S",
                windspeedKmph  => 24,
                windspeedMiles => 15
            },
            {
                date           => "2010-12-23",
                precipMM       => "0.0",
                tempMaxC       => 15,
                tempMaxF       => 59,
                tempMinC       => 5,
                tempMinF       => 41,
                weatherCode    => 113,
                weatherDesc    => [ { value => "Sunny" } ],
                weatherIconUrl => [
                    {
                        value =>
                          "http://free.worldweatheronline.com/images/wsymbols01_png_64/wsymbol_0001_sunny.png"
                    }
                ],
                winddir16Point => "NE",
                winddirDegree  => 38,
                winddirection  => "NE",
                windspeedKmph  => 12,
                windspeedMiles => 7
            }
        ]
    };

}
