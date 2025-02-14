#!perl -wT

use strict;
use warnings;
use Test::Most tests => 5;

BEGIN {
	use_ok('Weather::Meteo');
}

CARP: {
	eval 'use Test::Carp';

	if($@) {
		plan(skip_all => 'Test::Carp needed to check error messages');
	} else {
		does_croak_that_matches(
			sub {
				new_ok('Weather::Meteo')->weather()
			},
			qr/^Usage/
		);
		does_carp_that_matches(
			sub {
				new_ok('Weather::Meteo')->weather({ latitude => 160, longitude => -14, date => 'xyzzy' })
			},
			qr/is not a valid date/
		);
		done_testing();
	}
}
