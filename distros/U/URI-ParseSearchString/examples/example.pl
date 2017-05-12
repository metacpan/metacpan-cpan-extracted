#!/usr/bin/perl

use strict ;
use warnings;

use URI::ParseSearchString ;

my $uparse = new URI::ParseSearchString ;
my $ref_str = 'http://www.google.com/search?hl=en&q=this+is+an+example&btnG=Google+Search' ;

my $keywords = $uparse->parse_search_string( $ref_str ) ;
print "The keywords were: $keywords \n" ;
my $engine = $uparse->findEngine( $ref_str ) ;
print "The engine was: $engine \n" ;