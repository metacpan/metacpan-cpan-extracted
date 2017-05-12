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
my $website_name= 'test';

my $website	= new WebService::Eulerian::Analytics::Website( %h_api_params );
my $order	= new WebService::Eulerian::Analytics::Website::Order( %h_api_params );

my $rh_website	= $website->getByName($website_name);

die $website->faultcode()	if ( $website->fault );

if ( !scalar( keys %{ $rh_website } ) ) {
 die "website not found.\n";
}

my $rh_result	= $order->search( $rh_website->{website_id}, {
 'order-from'		=> '08/07/2009',
 'order-to'		=> '08/07/2009',
 
 'with-ordertype'	=> 1,	# with ordertype information : full JOIN
 'with-orderpage'	=> 1,	# fetch list of pages used to generate order

 'with-channel-level'	=> 1,	# fetch channel information
 'max-channel-level'	=> 1,	# depth of channel information
 'max-channel-info'	=> 5,	# level of information on channel

 'with-email'		=> 1,	# fetch email adress
 'with-ip'		=> 1,	# fetch IP adress
});

if ( $order->fault() ) {
 die $order->faultstring();
}

for ( @{ $rh_result->{result} } ) {
 my @a_page	= ();
 for ( my $i = 0; $i < $_->{a_orderpage_sz}; $i++ ) {
  push(@a_page, $_->{'orderpage_name_'.$i} || '');
 }
 print "> REF : ".$_->{order_ref}." | DATE : ".localtime($_->{order_date})." | ".
  " EMAIL : ".$_->{email_id}." | IP : ".$_->{order_ip}." | ".
  " CHANNEL : p0=".$_->{channel_lvl0_p0}." p1=".$_->{channel_lvl0_p1}." p2=".$_->{channel_lvl0_p2}." ".
  " p3=".$_->{channel_lvl0_p3}." p4=".$_->{channel_lvl0_p4}." | ".
  " ORDERTYPE : ".$_->{ordertype_key}." | ".
  " NUMBER OF PAGES : ".$_->{a_orderpage_sz}." | ".
  " PAGE LIST : ".join(',', @a_page)." <\n";

}
print "Total : ".$rh_result->{total}."\n";

1;
__END__
