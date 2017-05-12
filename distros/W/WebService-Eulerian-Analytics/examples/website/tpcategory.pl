#!/usr/bin/perl -w
#
# $Id: tpcategory.pl,v 1.1 2008-09-07 23:31:00 cvscore Exp $

use strict;
use WebService::Eulerian::Analytics::Website;
use WebService::Eulerian::Analytics::Website::TPCategory;

my %h_api_params	= (
 apikey	=> '',
 host 	=> '',
);
my $website_name	= '';
my $tpcategory_id	= '';
my $tpcategory_name	= '';

my $website	= new WebService::Eulerian::Analytics::Website( %h_api_params );
my $tpcategory	= new WebService::Eulerian::Analytics::Website::TPCategory( %h_api_params );

my $rh_website	= $website->getByName($website_name);

die $website->faultcode()	if ( $website->fault );

if ( !scalar( keys %{ $rh_website } ) ) {
 die "website not found.\n";
}

# search : fetch all tpcategory
my $rh_res	= $tpcategory->search($rh_website->{website_id}, {}, { sortdir => 'desc', limit => 20, start => 0 });
if ( $tpcategory->fault ) {
 die $tpcategory->faultstring();
}
print "Total count : ".($rh_res->{totalcount} || 0)."<\n";
for ( @{ $rh_res->{results} || [] } ) {
 print "\t name=".$_->{tpcategory_name}." | id=".$_->{tpcategory_id}."<\n";
}

# getById
my $rh_tpcategory	= $tpcategory->getById(
  $rh_website->{website_id},$tpcategory_id);
if ( $tpcategory->fault ) {
 die $tpcategory->faultstring();
}
print "getById : ".$rh_tpcategory->{tpcategory_name}."\n";

# getByName
$rh_tpcategory	= $tpcategory->getByName(
  $rh_website->{website_id}, $tpcategory_name);
if ( $tpcategory->fault ) {
 die $tpcategory->faultstring();
}
if ( ref( $rh_tpcategory ) ne 'HASH' ) {
 print "getByName : no results $tpcategory_name\n";
} else {
 print "getByName : ".$rh_tpcategory->{tpcategory_name}."\n";
}


1;
__END__
