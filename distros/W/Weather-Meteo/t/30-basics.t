#!/usr/bin/env perl

use strict;
use warnings;

use HTTP::Response;
use Test::Mockingbird;
use Test::Most;

BEGIN { use_ok('Weather::Meteo') }

# Mock the LWP::UserAgent to avoid actual API calls
mock 'LWP::UserAgent::get' => sub {
	my ($self, $url) = @_;

	# Simulated API response
	my $response = HTTP::Response->new(200);
	$response->content('{"hourly":{"temperature_2m":[5,6,7]}}');
	return $response;
};

# Test object creation
my $meteo = new_ok('Weather::Meteo');

# Test weather method with valid parameters
my $weather_data = $meteo->weather({ latitude => 51.34, longitude => 1.42, date => '2022-12-25' });
ok($weather_data, 'Weather data retrieved');
ok(exists($weather_data->{'hourly'}), 'Hourly data exists');

# Test invalid parameters
eval { $meteo->weather({ latitude => undef, longitude => 1.42, date => '2022-12-25' }) };
ok($@, 'Caught error for missing latitude');

# Test date validation
my $invalid_weather = $meteo->weather({ latitude => 51.34, longitude => 1.42, date => '1939-12-31' });
ok(!defined($invalid_weather), 'Invalid date (before 1940) returns undef');

# Test JSON parsing failure
mock 'LWP::UserAgent::get' => sub {
	my $response = HTTP::Response->new(200);
	$response->content('invalid json');
	return $response;
};

# Clear the cache to force using the invalid response
cmp_ok(ref($meteo->{'cache'}->get('weather:51.34:1.42:2022-12-25:Europe/London')), 'eq', 'HASH');
$meteo->{'cache'}->remove('weather:51.34:1.42:2022-12-25:Europe/London');

my $json_fail = $meteo->weather({ latitude => 51.34, longitude => 1.42, date => '2022-12-25' });
ok(!defined($json_fail), 'Invalid JSON response handled correctly');
diag(Data::Dumper->new([$json_fail])->Dump()) if($json_fail);

# Switch the mock back to a valid response for forecast and sunrise_sunset tests
mock 'LWP::UserAgent::get' => sub {
	my $response = HTTP::Response->new(200);
	$response->content('{"hourly":{"temperature_2m":[15,16,17],"rain":[0,0,0],'
		. '"snowfall":[0,0,0],"weathercode":[2,2,2]},'
		. '"daily":{"time":["2026-07-14"],'
		. '"sunrise":["2026-07-14T04:52"],"sunset":["2026-07-14T21:18"],'
		. '"weathercode":[2],"temperature_2m_max":[22.5],"temperature_2m_min":[14.2],'
		. '"rain_sum":[0.0],"snowfall_sum":[0.0],"precipitation_hours":[0.0],'
		. '"windspeed_10m_max":[15.3],"windgusts_10m_max":[28.7]}}');
	return $response;
};

# Test forecast method
my $forecast = $meteo->forecast({ latitude => 51.34, longitude => 1.42 });
ok($forecast, 'Forecast data retrieved');
ok(exists($forecast->{'hourly'}), 'Forecast hourly data exists');
ok(exists($forecast->{'daily'}{'sunrise'}), 'Forecast daily sunrise exists');

# Test sunrise_sunset method with a historical date (archive path)
mock 'LWP::UserAgent::get' => sub {
	my $response = HTTP::Response->new(200);
	$response->content('{"daily":{"time":["2022-12-25"],'
		. '"sunrise":["2022-12-25T08:09"],"sunset":["2022-12-25T15:57"]}}');
	return $response;
};

my $times = $meteo->sunrise_sunset({ latitude => 51.34, longitude => 1.42, date => '2022-12-25' });
ok($times, 'Sunrise/sunset data retrieved');
ok(exists($times->{'sunrise'}), 'Sunrise key present');
ok(exists($times->{'sunset'}),  'Sunset key present');

done_testing();
