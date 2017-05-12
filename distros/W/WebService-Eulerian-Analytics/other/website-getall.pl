#!/usr/bib/perl -w
#
# $Id: website-getall.pl,v 1.1 2008-09-03 18:46:02 cvscore Exp $

use strict;
use SOAP::Lite;
use Data::Dumper;

my $apikey	= 'YOUR_API_KEY';
my $host	= 'YOUR_API_HOST';

my $soap = SOAP::Lite->proxy( $host.'/ea/v1/Website' );

# header params for auth
my @a_hdr	= ( 
 SOAP::Header->name("apikey")->value( $apikey )->type('')
);

# additionnal params for method
my @a_p		= ();

my $result	= $soap->call(
   SOAP::Data->name('getAll')->uri('Website') => @a_hdr, @a_p );

if ( $result->fault ) {
 die $result->faultstring;
}

print Dumper($result->valueof('//getAllResponse/getAllReturn'));

1;
__END__
