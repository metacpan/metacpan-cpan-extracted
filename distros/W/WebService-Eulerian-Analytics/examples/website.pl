#!/usr/bin/perl -w
#
# $Id: website.pl,v 1.2 2008-09-03 18:46:02 cvscore Exp $

use strict;
use WebService::Eulerian::Analytics::Website;

# DEFINE INPUT FOR CALLS
my %h_api_params= (
 apikey		=> '',
 host		=> '',
);
my $WEBSITE_NAME= '';
my $WEBSITE_ID	= 0;

my $api	= new WebService::Eulerian::Analytics::Website( %h_api_params ); 

# non-existent website
print "\n", "-" x 80,"\n";
my $rh_website = $api->getById(0);
if ( $api->fault ) {
 print "getById : [FAULT] : ".$api->faultstring()."\n";
}
print "-" x 80,"\n";

# get website by id
print "\n", "-" x 80,"\n";
$rh_website = $api->getById($WEBSITE_ID);
if ( $api->fault ) {
 print "getById : [FAULT] : ".$api->faultstring()."\n";
}
print "getById : id=$WEBSITE_ID name=".($rh_website->{website_name} || '')."\n";
print "-" x 80,"\n";

# get website by name
print "\n", "-" x 80,"\n";
$rh_website = $api->getByName($WEBSITE_NAME);
if ( $api->fault ) {
 print "getByName : [FAULT] : ".$api->faultstring()."\n";
}
print "getByName : name=$WEBSITE_NAME id=".($rh_website->{website_id} || 0)."\n";
print "-" x 80,"\n";

# all website
print "\n", "-" x 80,"\n";
my $ra_website = $api->getAll();
if ( $api->fault ) {
 print "getByAll : [FAULT] : ".$api->faultstring()."\n";
}
print "getAll : \n";
for ( @{ $ra_website || [] } ) {
 print "\tid=".$_->{website_id}."\t | name=".$_->{website_name}."\n";
}
print "-" x 80,"\n";


1;
__END__
