#!/usr/bin/perl -w
# -*- perl -*-

#
# $Id: base.t,v 1.4 2003/05/16 18:17:47 eserte Exp $
# Author: Slaven Rezic
#

use strict;

BEGIN {
    if (!eval q{
	use Test;
	1;
    }) {
	print "1..0 # tests only work with installed Test module\n";
	exit;
    }
}

BEGIN { plan tests => 12 }

# just check that all modules can be compiled
ok(eval {require GPS::Garmin; 1}, 1, $@);
ok(eval {require GPS::Serial; 1}, 1, $@);
ok(eval {require GPS::Garmin::Handler; 1}, 1, $@);
ok(eval {require GPS::Garmin::Constant; 1}, 1, $@);
ok(eval {require GPS::NMEA; 1}, 1, $@);
ok(eval {require GPS::NMEA::Handler; 1}, 1, $@);

my $garmin = GPS::Garmin->new(do_not_init => 1);
ok(ref $garmin, "GPS::Garmin");
ok($garmin->isa("GPS::Base"));

my $nmea = GPS::NMEA->new(do_not_init => 1);
ok(ref $nmea, "GPS::NMEA");
ok($nmea->isa("GPS::Base"));

my $factory = GPS::Base->new(do_not_init => 1,
			     Protocol => 'GRMN',
			    );
ok(ref $factory, "GPS::Garmin");
ok($factory->isa("GPS::Base"));
