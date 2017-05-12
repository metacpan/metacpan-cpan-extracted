#!/usr/bin/perl -w
#
# $Id: order.pl,v 1.2 2008-09-03 18:46:02 cvscore Exp $

use strict;
use WebService::Eulerian::Analytics::Website;
use WebService::Eulerian::Analytics::Website::Order;

my %h_api_params	= (
 apikey	=> '',
 host 	=> '',
);
my $website_name	= 'test';

my $website	= new WebService::Eulerian::Analytics::Website( %h_api_params );
my $order	= new WebService::Eulerian::Analytics::Website::Order( %h_api_params );

my $rh_website	= $website->getByName($website_name);

die $website->faultcode()	if ( $website->fault );

if ( !scalar( keys %{ $rh_website } ) ) {
 die "website not found.\n";
}

# 2008-06-30 23:35
my %h_d	= (
  reference	=> 'test-'.time(),
  amount	=> '44.23',
  epoch		=> time() - 24 * 3600 * 5,
  type		=> 'Test',
  payment	=> 'CB'
  );
my $order_id = $order->replay($rh_website->{website_id}, \%h_d);

die $order->faultcode()	if ( $order->fault );

print STDERR "Order Id after replay is $order_id\n";


1;
__END__
