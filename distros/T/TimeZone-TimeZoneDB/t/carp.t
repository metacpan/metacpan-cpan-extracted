#!perl -wT

use strict;
use warnings;
use Test::Most;

CARP: {
	eval 'use Test::Carp';

	if($@) {
		plan(skip_all => 'Test::Carp needed to check error messages');
	} elsif(!$ENV{'TIMEZONEDB_KEY'}) {
		plan(skip_all => 'Set TIMEZONEDB_KEY for your API key to timezonedb.com');
	} else {
		plan(tests => 6);
		use_ok('TimeZone::TimeZoneDB');
		my $tzdb = new_ok('TimeZone::TimeZoneDB' => [ key => $ENV{'TIMEZONEDB_KEY'} ]);

		does_carp_that_matches(sub { my $tz = $tzdb->get_time_zone(); }, qr/^Usage: /);
		does_carp_that_matches(sub { my $tz = $tzdb->get_time_zone(latitude => undef); }, qr/^Usage: /);
		does_carp_that_matches(sub { my $tz = $tzdb->get_time_zone({ longitude => undef }); }, qr/^Usage: /);

		does_carp_that_matches(sub { my $tzdb = TimeZone::TimeZoneDB->new(); }, qr/argument not given/);
		done_testing();
	}
}
