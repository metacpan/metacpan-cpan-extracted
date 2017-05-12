#!/usr/bin/perl -w
#
# $Id: tpmedia.pl,v 1.1 2008-09-07 23:31:00 cvscore Exp $

use strict;
use WebService::Eulerian::Analytics::Website;
use WebService::Eulerian::Analytics::Website::TPMedia;

my %h_api_params	= (
 apikey	=> '',
 host 	=> '',
);
my $website_name= '';
my $tpmedia_id	= '';
my $tpmedia_name= '';

my $website	= new WebService::Eulerian::Analytics::Website( %h_api_params );
my $tpmedia	= new WebService::Eulerian::Analytics::Website::TPMedia( %h_api_params );

my $rh_website	= $website->getByName($website_name);

die $website->faultcode()	if ( $website->fault );

if ( !scalar( keys %{ $rh_website } ) ) {
 die "website not found.\n";
}

# search : fetch all tpmedia
my $rh_res	= $tpmedia->search($rh_website->{website_id}, {}, { sortdir => 'desc', limit => 20, start => 0 });
if ( $tpmedia->fault ) {
 die $tpmedia->faultstring();
}
print "Total count : ".($rh_res->{totalcount} || 0)."<\n";
for ( @{ $rh_res->{results} || [] } ) {
 print "\t name=".$_->{tpmedia_name}." | id=".$_->{tpmedia_id}."<\n";
}

# getById
my $rh_tpmedia	= $tpmedia->getById(
  $rh_website->{website_id},$tpmedia_id);
if ( $tpmedia->fault ) {
 die $tpmedia->faultstring();
}
print "getById : ".$rh_tpmedia->{tpmedia_name}."\n";

# getByName
$rh_tpmedia	= $tpmedia->getByName(
  $rh_website->{website_id}, $tpmedia_name);
if ( $tpmedia->fault ) {
 die $tpmedia->faultstring();
}
if ( ref( $rh_tpmedia ) ne 'HASH' ) {
 print "getByName : no results $tpmedia_name\n";
} else {
 print "getByName : ".$rh_tpmedia->{tpmedia_name}."\n";
}


1;
__END__
