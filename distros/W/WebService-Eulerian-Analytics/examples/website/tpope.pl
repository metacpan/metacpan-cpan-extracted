#!/usr/bin/perl -w
#
# $Id: tpope.pl,v 1.2 2008-09-30 00:55:09 cvscore Exp $

use strict;
use WebService::Eulerian::Analytics::Website;
use WebService::Eulerian::Analytics::Website::TPOpe;

my %h_api_params	= (
 apikey	=> '',
 host 	=> '',
);
my $website_name= 'test';
my $tpope_id	= '1';
my $tpope_name	= '';

my $website	= new WebService::Eulerian::Analytics::Website( %h_api_params );
my $tpope	= new WebService::Eulerian::Analytics::Website::TPOpe( %h_api_params );

my $rh_website	= $website->getByName($website_name);

die $website->faultcode()	if ( $website->fault );

if ( !scalar( keys %{ $rh_website } ) ) {
 die "website not found.\n";
}

# search : fetch all tpope
my $rh_res	= $tpope->search($rh_website->{website_id}, {}, { sortdir => 'desc', limit => 20, start => 0 });
if ( $tpope->fault ) {
 die $tpope->faultstring();
}
print "Total count : ".($rh_res->{totalcount} || 0)."<\n";
for ( @{ $rh_res->{results} || [] } ) {
 print "\t name=".$_->{tpope_name}." | id=".$_->{tpope_id}." | type=".$_->{tpope_type}."<\n";
}

# getById
my $rh_tpope	= $tpope->getById(
  $rh_website->{website_id},$tpope_id);
if ( $tpope->fault ) {
 die $tpope->faultstring();
}
print "getById : ".$rh_tpope->{tpope_name}."\n";

# getByName
$rh_tpope	= $tpope->getByName(
  $rh_website->{website_id}, $tpope_name);
if ( $tpope->fault ) {
 die $tpope->faultstring();
}
if ( ref( $rh_tpope ) ne 'HASH' ) {
 print "getByName : no results $tpope_name\n";
} else {
 print "getByName : ".$rh_tpope->{tpope_name}."\n";
}


1;
__END__
