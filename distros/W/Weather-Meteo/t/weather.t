#!perl -wT

use warnings;
use strict;
use Test::Most tests => 4;

BEGIN {
	use_ok('Weather::Meteo');
}

WEATHER: {
	SKIP: {
		if(!-e 't/online.enabled') {
			if(!$ENV{AUTHOR_TESTING}) {
				diag('Author tests not required for installation');
				skip('Author tests not required for installation', 3);
			} else {
				diag('Test requires Internet access');
				skip('Test requires Internet access', 3);
			}
		}

		# Weather in Ramsgate on Christmas Day 2022
		my $meteo = new_ok('Weather::Meteo');
		my $weather = $meteo->weather({ latitude => 51.34, longitude => 1.42, date => '2022-12-25' });
		cmp_ok(scalar(@{$weather->{'hourly'}->{'rain'}}), '==', 24, '24 sets of hourly rainfall data');
		my @rain = @{$weather->{'hourly'}->{'rain'}};
		isnt(qr/\D/, $rain[1]);	# Must only be digits

		if($ENV{'TEST_VERBOSE'}) {
			diag(Data::Dumper->new([$weather])->Dump());
		}
	}
}
