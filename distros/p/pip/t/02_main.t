#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 10;
use File::Spec::Functions ':ALL';
use Module::Plan::Base;
use Params::Util ':ALL';





#####################################################################
# Constructor Testing

# ... with the full name
SKIP: {
	skip("Only tested when run as root", 10) unless $< == 0;
	my $plan = Module::Plan::Base->read( catfile('t','data','default.p5i') );
	isa_ok( $plan, 'Module::Plan::Lite' );
	ok( _STRING($plan->p5i), '->p5i ok' );
	isa_ok( $plan->p5i_uri, 'URI::file' );
	isa_ok( $plan->p5i_dir, 'URI::file' );
	is( $plan->p5i_uri->scheme, 'file', '->p5i_uri ok' );
	is( $plan->p5i_dir->scheme, 'file', '->p5i_dir ok' );
	ok( $plan->dir, 'Got a ->dir value' );
	ok( -d $plan->dir, '->dir exists' );
	ok( -w $plan->dir, '->dir is writable' );
	isa_ok( $plan->inject, 'CPAN::Inject' );
}
