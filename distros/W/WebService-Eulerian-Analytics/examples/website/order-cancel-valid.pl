#!/usr/bin/perl -w
#
# $Id: order.pl,v 1.2 2008-09-03 18:46:02 cvscore Exp $

use strict;
use SOAP::Lite +trace => 'debug';
use WebService::Eulerian::Analytics::Website;
use WebService::Eulerian::Analytics::Website::Order;

my %h_api_params	= (
 apikey	=> '',
 host 	=> '',
);
my $website_name= 'test';

my $website	= new WebService::Eulerian::Analytics::Website( %h_api_params );
my $order	= new WebService::Eulerian::Analytics::Website::Order( %h_api_params );

my $rh_website	= $website->getByName($website_name);

die $website->faultcode()	if ( $website->fault );

if ( !scalar( keys %{ $rh_website } ) ) {
 die "website not found.\n";
}

# cancel
my $rh_result_c	= $order->cancel( $rh_website->{website_id}, 'XXXXXX', 'YYYYY' );

if ( $order->fault() ) {
 die $order->faultstring();
}

# valid
my $rh_result_v	= $order->valid( $rh_website->{website_id}, 'XXXXXX', 'YYYYY' );

if ( $order->fault() ) {
 die $order->faultstring();
}


1;
__END__
