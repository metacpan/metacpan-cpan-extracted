#!/usr/bin/evn perl

use strict;
use warnings;
use version; our $VERSION = qv('0.03');

#use blib;
use Test::Base tests => 3;

use WebService::Ustream::API;

can_ok( 'WebService::Ustream::API', qw(new key ua) );

SKIP: {
	if ( !$ENV{TEST_USTREAM} ) {
		skip 'set TEST_USTREAM for testing WebService::Ustream::API', 2;
	}
	my $ust = WebService::Ustream::API->new;	
	$ust->key( $ENV{TEST_USTREAM} );
	isa_ok( $ust->user, 'WebService::Ustream::API::User' );
	isa_ok( $ust->stream, 'WebService::Ustream::API::Stream' );
}
