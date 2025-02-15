#!perl -wT

use warnings;
use strict;
use Test::Most tests => 12;
use Geo::Location::Point 0.09;

BEGIN {
	use_ok('Weather::Meteo');
}

WEATHER: {
	my $meteo = new_ok('Weather::Meteo');

	SKIP: {
		if(-e 't/online.enabled') {
			require DateTime;
			DateTime->import();
		} elsif($ENV{'AUTHOR_TESTING'}) {
			diag('Test requires Internet access');
			skip('Test requires Internet access', 10);
		} else {
			diag('Author tests not required for installation');
			skip('Author tests not required for installation', 10);
		}
		# Weather in Ramsgate on Christmas Day 2022
		my $weather = $meteo->weather({ latitude => 51.34, longitude => 1.42, date => '2022-12-25' });
		ok(defined($weather), 'We get data back');
		cmp_ok(scalar(@{$weather->{'hourly'}->{'rain'}}), '==', 24, '24 sets of hourly rainfall data');
		my @rain = @{$weather->{'hourly'}->{'rain'}};
		isnt(qr/\D/, $rain[1]);	# Must only be digits

		if($ENV{'TEST_VERBOSE'}) {
			diag(Data::Dumper->new([$weather])->Dump());
		}

		my $location;
		if(my $key = $ENV{'TIMEZONEDB_KEY'}) {
			$location = new_ok('Geo::Location::Point' => [ latitude => 51.34, longitude => 1.42, key => $key ]);
		} else {
			$location = new_ok('Geo::Location::Point' => [ latitude => 51.34, longitude => 1.42 ]);
		}
		$weather = $meteo->weather($location, '2022-12-25');
		cmp_ok(scalar(@{$weather->{'hourly'}->{'rain'}}), '==', 24, '24 sets of hourly rainfall data');
		@rain = @{$weather->{'hourly'}->{'rain'}};
		isnt(qr/\D/, $rain[1]);	# Must only be digits

		$weather = $meteo->weather({ location => $location, date => new_ok('DateTime' => [ year => 2000, month => 6, day => 5 ]) });

		$weather = $meteo->weather(latitude => 51.283333, longitude => .4, date => '1970-02-12');
		is(ref($weather), 'HASH');

		# Data prior to 1940 is not in the database

		is($meteo->weather(latitude => 51.34, longitude => 1.42, date => '1704-11-14'), undef, 'pre 1940 data is not found');

		is(ref($meteo->ua()), 'LWP::UserAgent', 'get ua works');
	}
}
