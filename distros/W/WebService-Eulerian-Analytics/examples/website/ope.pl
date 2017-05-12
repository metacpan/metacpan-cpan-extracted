#!/usr/bin/perl -w
#
# $Id: ope.pl,v 1.1 2008-09-30 00:55:09 cvscore Exp $

use strict;
use WebService::Eulerian::Analytics::Website;
use WebService::Eulerian::Analytics::Website::Ope;

my %h_api_params	= (
 apikey	=> '',
 host 	=> '',
);
my $website_name= 'test';
my $ope_id	= 1;
my $ope_name	= 'test';

my $website	= new WebService::Eulerian::Analytics::Website( %h_api_params );
my $ope	= new WebService::Eulerian::Analytics::Website::Ope( %h_api_params );

my $rh_website	= $website->getByName($website_name);

die $website->faultcode()	if ( $website->fault );

if ( !scalar( keys %{ $rh_website } ) ) {
 die "website not found.\n";
}

# search : fetch all ope
my $rh_res	= $ope->search($rh_website->{website_id}, {}, { sortdir => 'desc', limit => 20, start => 0 });
if ( $ope->fault ) {
 die $ope->faultstring();
}
print "Total count : ".($rh_res->{totalcount} || 0)."<\n";
for ( @{ $rh_res->{results} || [] } ) {
 print "\t name=".$_->{ope_name}." | id=".$_->{ope_id}." | type=".$_->{ope_type}."<\n";
}

# getById
my $rh_ope	= $ope->getById(
  $rh_website->{website_id},$ope_id);
if ( $ope->fault ) {
 die $ope->faultstring();
}
print "getById : ".$rh_ope->{ope_name}."\n";

# getByName
my $rh_ope2	= $ope->getByName(
  $rh_website->{website_id}, $ope_name) || {};
if ( $ope->fault ) {
 die $ope->faultstring();
}
if ( ref( $rh_ope2 ) ne 'HASH' ) {
 print "getByName : no results $ope_name\n";
} else {
 print "getByName : ".$rh_ope2->{ope_name}."\n";
}

# getURL
my $rh_url = $ope->getURL($rh_website->{website_id}, 
  $rh_ope->{ope_id}, { limit => 20 });
print "Total count : ".($rh_url->{totalcount} || 0)."<\n";
for ( @{ $rh_url->{results} || [] } ) {
 print "\t url=".$_->{opedata_clickthruurl}." | id=".$_->{opedata_id}."<\n";
}


1;
__END__
