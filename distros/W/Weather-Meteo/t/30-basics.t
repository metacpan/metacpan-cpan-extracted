#!/usr/bin/env perl

use strict;
use warnings;

use HTTP::Response;
use Test::MockModule;
use Test::Most;

BEGIN { use_ok('Weather::Meteo') }

# Mock the LWP::UserAgent to avoid actual API calls
my $mock_ua = Test::MockModule->new('LWP::UserAgent');
$mock_ua->mock(get => sub {
	my ($self, $url) = @_;

	# Simulated API response
	my $response = HTTP::Response->new(200);
	$response->content('{"hourly":{"temperature_2m":[5,6,7]}}');
	return $response;
});

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
$mock_ua->mock(get => sub {
	my $response = HTTP::Response->new(200);
	$response->content('invalid json');
	return $response;
});

# Clear the cache to force using the invalid response
cmp_ok(ref($meteo->{'cache'}->get('weather:51.34:1.42:2022-12-25:Europe/London')), 'eq', 'HASH');
$meteo->{'cache'}->remove('weather:51.34:1.42:2022-12-25:Europe/London');

my $json_fail = $meteo->weather({ latitude => 51.34, longitude => 1.42, date => '2022-12-25' });
ok(!defined($json_fail), 'Invalid JSON response handled correctly');
diag(Data::Dumper->new([$json_fail])->Dump()) if($json_fail);

done_testing();
