#!/usr/local/bin/perl -w

=head1 NAME

foo.t - Tests some of the examples in XML::Doctype's POD

=cut

package Foo ;
use Test ;

package main ;

use strict ;
use Test ;
use XML::Doctype ;
use UNIVERSAL qw( isa ) ;

my $w ;
my $doctype ;

my $dtd = <<TOHERE ;
<!ELEMENT a ( b1, b2?, b3* ) >

    <!ATTLIST   a aa1 CDATA       #REQUIRED >

<!ELEMENT b1 ( c1 ) >
<!ELEMENT b2 ( c2 ) >
<!ELEMENT b3 ( c3 ) >
TOHERE


my $buf ;

my @tests = (

sub {
   $buf = '' ;

   eval <<ENDEXAMPLE1 ;
package Example1 ;

use XML::Doctype     NAME => 'a', DTD_TEXT => <<TOHERE ;
<!ELEMENT a ( b1, b2?, b3* ) >

    <!ATTLIST   a aa1 CDATA       #REQUIRED >

<!ELEMENT b1 ( c1 ) >
<!ELEMENT b2 ( c2 ) >
<!ELEMENT b3 ( c3 ) >
<!ELEMENT c1 ( #PCDATA ) >
TOHERE

use XML::AutoWriter qw( :all :dtd_tags ) ;
select_xml \\\$buf ;

getDoctype->element_decl('a')->attdef('aa1')->default_on_write('foo') ;
xmlDecl ;
start_a( attr => 'val' );
c1;
c2;
end_a;
ENDEXAMPLE1

   die $@ if $@ ;

   $buf =~ s/\n//g ;
   ok( $buf, qq{<?xml version="1.0"?><a attr="val" aa1="foo"><b1><c1 /></b1><b2><c2 /></b2></a>} ) ;
},
) ;

plan tests => scalar @tests ;

## Do this after planing so that the test harness can see that we 
## started, then failed.
package Foo ;
use XML::Doctype ;

package ::main ;
use XML::Doctype ;

$_->() for @tests ;

