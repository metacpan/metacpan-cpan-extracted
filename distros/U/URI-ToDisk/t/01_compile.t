#!/usr/bin/perl -w

# Load test the URI::ToDisk module

use strict;
use lib ();
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		# Setup some things if running outside of a proper Test::Harness
		require FindBin;
		$FindBin::Bin = $FindBin::Bin; # Avoid a warning
		chdir catdir( $FindBin::Bin, updir() );
		lib->import(
			catdir('blib', 'lib'),
			catdir('blib', 'arch'),
			'lib',
			);
	}
}





# Does everything load?
use Test::More tests => 2;
ok( $] >= 5.005, 'Your perl is new enough' );
use_ok( 'URI::ToDisk' );

1;
