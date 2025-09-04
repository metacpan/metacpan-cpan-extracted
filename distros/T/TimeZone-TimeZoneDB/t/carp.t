#!perl -wT

use strict;
use warnings;

use Test::Most;
use Test::Needs 'Test::Carp';

CARP: {
	Test::Carp->import();

	if(!$ENV{'TIMEZONEDB_KEY'}) {
		plan(skip_all => 'Set TIMEZONEDB_KEY for your API key to timezonedb.com');
	} else {
		plan(tests => 6);
		use_ok('TimeZone::TimeZoneDB');
		my $tzdb = new_ok('TimeZone::TimeZoneDB' => [ key => $ENV{'TIMEZONEDB_KEY'} ]);

		throws_ok {
			my $tz = $tzdb->get_time_zone();
		} qr/Required parameter/, 'Dies when missing parameters';
		throws_ok {
			my $tz = $tzdb->get_time_zone(latitude => undef);
		} qr/Required parameter/, 'Dies when missing parameters';

		throws_ok {
			my $tz = $tzdb->get_time_zone({ longitude => undef });
		} qr/Required parameter/, 'Dies when missing parameters';

		does_croak_that_matches(sub { TimeZone::TimeZoneDB->new() }, qr/is required/);
		done_testing();
	}
}
