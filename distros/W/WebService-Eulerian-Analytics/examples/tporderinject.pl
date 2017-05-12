#!/usr/bin/perl -w
#
# $Id: tporderinject.pl,v 1.3 2008-09-03 18:46:02 cvscore Exp $

use strict;
use WebService::Eulerian::Analytics::TPOrderInject;

# tporder params
my %h_tporder_p	= (
 clickoutid	=> 'CLICKOUT_ID_AS_PROVIDED_BY_PARTNER',
 tppublisher	=> 'NAME_OF_PARTNER_AS_DECLARED_IN_EA',
 reference	=> 'reference-'.time(),
 amount		=> 10.9,
 epoch		=> time(),
);
my $my_websitegroup_name	= 'MY_GROUP';

my $api	= new WebService::Eulerian::Analytics::TPOrderInject( 
 apikey	=> '',
 host 	=> ''
);

# replay : tporder for a given 
my $ret = $api->replay( $my_websitegroup_name, \%h_tporder_p );

if ( $api->fault ) {
 die $api->faultstring();
}

print "OK !\n";

1;
__END__
