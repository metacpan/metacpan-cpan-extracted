# $Id: 10-parse.t,v 1.2 2004/10/17 02:51:56 asc Exp $

use strict;
use Test::More;

plan tests => 4;

my $vcard = "t/Senzala.vcf";

use_ok("XML::Generator::vCard::RDF");

ok((-f $vcard),"found $vcard");

my $parser = XML::Generator::vCard::RDF->new();
isa_ok($parser,"XML::Generator::vCard::RDF");

ok($parser->parse_files($vcard,@ARGV),"parsed $vcard");
