#!perl -wT

use warnings;
use strict;
use Test::Most tests => 9;
use Geo::Location::Point 0.08;

BEGIN {
	use_ok('Weather::Meteo');
}

WEATHER: {
	SKIP: {
		my $meteo = new_ok('Weather::Meteo');

		if(!-e 't/online.enabled') {
			if(!$ENV{AUTHOR_TESTING}) {
				diag('Author tests not required for installation');
				skip('Author tests not required for installation', 7);
			} else {
				diag('Test requires Internet access');
				skip('Test requires Internet access', 7);
			}
		}

		# Weather in Ramsgate on Christmas Day 2022
		my $weather = $meteo->weather({ latitude => 51.34, longitude => 1.42, date => '2022-12-25' });
		cmp_ok(scalar(@{$weather->{'hourly'}->{'rain'}}), '==', 24, '24 sets of hourly rainfall data');
		my @rain = @{$weather->{'hourly'}->{'rain'}};
		isnt(qr/\D/, $rain[1]);	# Must only be digits

		if($ENV{'TEST_VERBOSE'}) {
			diag(Data::Dumper->new([$weather])->Dump());
		}

		my $location = new_ok('Geo::Location::Point' => [ latitude => 51.34, longitude => 1.42 ]);
		$weather = $meteo->weather($location, '2022-12-25');
		cmp_ok(scalar(@{$weather->{'hourly'}->{'rain'}}), '==', 24, '24 sets of hourly rainfall data');
		@rain = @{$weather->{'hourly'}->{'rain'}};
		isnt(qr/\D/, $rain[1]);	# Must only be digits

		# Data prior to 1940 is not in the database

		is($meteo->weather(latitude => 51.34, longitute => 1.42, date => '1704-11-14'), undef, 'pre 1940 data is not found');

		is(ref($meteo->ua()), 'LWP::UserAgent', 'get ua works');
	}
}
