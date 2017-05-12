#!/usr/bin/perl -w

# Load test the Test::Object module

use strict;
use lib ();
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		$FindBin::Bin = $FindBin::Bin; # Avoid a warning
		chdir catdir( $FindBin::Bin, updir() );
		lib->import(
			catdir('blib', 'arch'),
			catdir('blib', 'lib' ),
			catdir('lib'),
			);
	}
}

# Does everything load?
use Test::More 'tests' => 2;
ok( $] >= 5.005, 'Your perl is new enough' );
use_ok( 'Test::Object' );

1;
