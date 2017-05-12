# $Id: 10-parse.t,v 1.1 2004/10/06 22:03:31 asc Exp $

use strict;
use Test::More;

plan tests => 4;

my $vcard = "t/Senzala.vcf";

use_ok("XML::Generator::vCard");

ok((-f $vcard),"found $vcard");

my $parser = XML::Generator::vCard->new();

isa_ok($parser,"XML::Generator::vCard");

ok($parser->parse_files($vcard),"parsed $vcard");
