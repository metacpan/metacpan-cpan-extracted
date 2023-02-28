#!perl -wT

use warnings;
use strict;
use Test::Most tests => 3;

BEGIN {
	use_ok('Weather::Meteo');
}

WEATHER: {
	SKIP: {
		if(!-e 't/online.enabled') {
			if(!$ENV{AUTHOR_TESTING}) {
				diag('Author tests not required for installation');
				skip('Author tests not required for installation', 2);
			} else {
				diag('Test requires Internet access');
				skip('Test requires Internet access', 2);
			}
		}

		# Weather in Ramsgate on Christmas Day 2022
		my $meteo = new_ok('Weather::Meteo');
		my $weather = $meteo->weather({ latitude => 51.34, longitude => 1.42, date => '2022-12-25' });
		cmp_ok(scalar(@{$weather->{'hourly'}->{'rain'}}), '==', 24, '24 sets of hourly rainfall data');

		if($ENV{'TEST_VERBOSE'}) {
			diag(Data::Dumper->new([$weather])->Dump());
		}
	}
}
