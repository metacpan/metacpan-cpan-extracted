#!/usr/bin/perl -w                                            # -*- perl -*-
#
# Test the XML::Namespace module.
#
# Written by Andy Wardley <mailto:abw@cpan.org>
#
# This is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#

use strict;
use warnings;
use lib qw( ./lib ../lib );
use XML::Namespace;
use Test::More tests => 10;

my $xsd = 'http://www.w3.org/2001/XMLSchema#';
my $rdf = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#';


#------------------------------------------------------------------------
# test XML::Namespace object
#------------------------------------------------------------------------

my $ns = XML::Namespace->new($xsd);

is( $ns->uri, "$xsd", 'got xsd uri' ); 
is( $ns->uri('integer'), "${xsd}integer", 'got xsd integer via uri()' ); 

is( $ns->integer, "${xsd}integer", 'got xsd integer via integer()' ); 


#------------------------------------------------------------------------
# check we get an error if no URI parameter passed
#------------------------------------------------------------------------

eval {
    my $dud = XML::Namespace->new();
};
ok( $@, 'missing URI parameter error');


#------------------------------------------------------------------------
# test overloaded methods
#------------------------------------------------------------------------

my $ns1 = XML::Namespace->new($xsd);
my $ns2 = XML::Namespace->new($xsd);

is( "$ns1", "$xsd", 'got xsd uri through stringification' ); 
ok( $ns1 eq $ns2, 'compared namespaces' ); 



#------------------------------------------------------------------------
# test the import method
#------------------------------------------------------------------------

use XML::Namespace
    xsd => 'http://www.w3.org/2001/XMLSchema#',
    rdf => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#' ;

is( xsd->uri('integer'), "${xsd}integer", 'got xsd integer via uri()' ); 
is( xsd->integer, "${xsd}integer", 'got xsd integer' ); 

is( rdf->type, "${rdf}type", 'got rdf type' ); 


#------------------------------------------------------------------------
# test the import method directly
#------------------------------------------------------------------------

use XML::Namespace;

XML::Namespace->import( foo => 'http://myfoo.com/' );
is( foo()->hello, 'http://myfoo.com/hello', 'hello foo' );
