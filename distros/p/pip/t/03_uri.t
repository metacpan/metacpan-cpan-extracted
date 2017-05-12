#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
use LWP::Online 'online';
use t::lib::Test;

unless ( user_owns_cpan() ) {
	plan( skip_all => "This test requires you to have CPAN client permissions" );
}

unless ( online('http') ) {
	plan( skip_all => "This test requires intarweb access" );
	exit(0);
}

plan( tests => 9 );

use File::Spec::Functions ':ALL';
use Module::Plan::Base;





#####################################################################
# Constructor Testing

# Test with the repository URI
SKIP: {
	skip("Cannot test unless running as root", 9) unless $< == 0;
	my $plan = Module::Plan::Base->read(
		catdir(qw{ t data 03_uri.p5i })
		);
	isa_ok( $plan, 'Module::Plan::Lite' );

	# Check the uris
	SCOPE: {
		my %uris = $plan->uris;
		is( scalar(keys %uris), 2, '2 uris added' );
		my %dists = $plan->dists;
		is( scalar(keys %dists), 0, '0 dists fetched' );
		foreach ( values %uris ) {
			isa_ok( $_, 'URI' );
		}
	}

	# Fetch the files
	SCOPE: {
		ok( $plan->fetch, 'Fetched modules ok' );
		my %dists = $plan->dists;
		is( scalar(keys %dists), 2, '2 dists fetched' );
		foreach ( values %dists ) {
			ok( -f $_, "File $_ exists" );
		}
	}
}
