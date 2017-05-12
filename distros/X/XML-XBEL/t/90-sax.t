use strict;
use Test::More;

plan tests => 6;

use_ok("XML::XBEL");
use_ok("XML::LibXML::SAX::Builder");

my $xbel = XML::XBEL->new();
isa_ok($xbel,"XML::XBEL");

my $builder = XML::LibXML::SAX::Builder->new();
isa_ok($builder,"XML::LibXML::SAX::Builder");

ok($xbel->parse_file("./t/test.xbel"),
   "parsed xbel");

ok($xbel->toSAX($builder));

# $Id: 90-sax.t,v 1.1 2004/07/03 06:14:21 asc Exp $
