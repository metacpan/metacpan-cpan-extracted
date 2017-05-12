#!/usr/bin/perl 

use Test::More tests => 2;
use XML::Writer::Simple xml => "t/03-xml.xml";

is(zbr(), "<zbr/>");
is(foo(bar("ugh")), "<foo><bar>ugh</bar></foo>");
