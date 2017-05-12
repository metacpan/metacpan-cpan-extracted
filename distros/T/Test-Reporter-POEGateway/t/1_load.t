#!/usr/bin/perl
use strict; use warnings;

my $numtests;
BEGIN {
	$numtests = 3;

	eval "use Test::NoWarnings";
	if ( ! $@ ) {
		# increment by one
		$numtests++;

	}
}

use Test::More tests => $numtests;

use_ok( 'Test::Reporter::POEGateway' );
use_ok( 'Test::Reporter::POEGateway::Mailer' );
use_ok( 'Test::Reporter::POEGateway::Mailer::SMTP' );
