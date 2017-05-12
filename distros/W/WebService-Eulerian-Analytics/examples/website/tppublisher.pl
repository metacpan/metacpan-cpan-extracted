#!/usr/bin/perl -w
#
# $Id: tppublisher.pl,v 1.1 2008-09-07 23:31:00 cvscore Exp $

use strict;
use WebService::Eulerian::Analytics::Website;
use WebService::Eulerian::Analytics::Website::TPPublisher;

my %h_api_params	= (
 apikey	=> '',
 host 	=> '',
);
my $website_name	= '';
my $tppublisher_id	= '';
my $tppublisher_name	= '';

my $website	= new WebService::Eulerian::Analytics::Website( %h_api_params );
my $tppublisher	= new WebService::Eulerian::Analytics::Website::TPPublisher( %h_api_params );

my $rh_website	= $website->getByName($website_name);

die $website->faultcode()	if ( $website->fault );

if ( !scalar( keys %{ $rh_website } ) ) {
 die "website not found.\n";
}

# search : fetch all tppublisher
my $rh_res	= $tppublisher->search($rh_website->{website_id}, {}, { sortdir => 'desc', limit => 20, start => 0 });
if ( $tppublisher->fault ) {
 die $tppublisher->faultstring();
}
print "Total count : ".($rh_res->{totalcount} || 0)."<\n";
for ( @{ $rh_res->{results} || [] } ) {
 print "\t name=".$_->{tppublisher_name}." | id=".$_->{tppublisher_id}."<\n";
}

# getById
my $rh_tppublisher	= $tppublisher->getById(
  $rh_website->{website_id},$tppublisher_id);
if ( $tppublisher->fault ) {
 die $tppublisher->faultstring();
}
print "getById : ".$rh_tppublisher->{tppublisher_name}."\n";

# getByName
$rh_tppublisher	= $tppublisher->getByName(
  $rh_website->{website_id}, $tppublisher_name);
if ( $tppublisher->fault ) {
 die $tppublisher->faultstring();
}
if ( ref( $rh_tppublisher ) ne 'HASH' ) {
 print "getByName : no results $tppublisher_name\n";
} else {
 print "getByName : ".$rh_tppublisher->{tppublisher_name}."\n";
}


1;
__END__
