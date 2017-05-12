# $Id: 20-write.t,v 1.5 2004/12/28 21:50:07 asc Exp $

use strict;
use Test::More;

plan tests => 7;

SKIP: {
  eval { 
    require XML::SAX::Writer;
  };

  if ($@) {
    skip("XML::SAX::Writer not installed", 7);
  }

  use_ok("XML::Generator::vCard");
  use_ok("XML::SAX::Writer");
  
  #
  
  my $vcard = "t/Senzala.vcf";
  ok((-f $vcard),"found $vcard");
  
  #
  
  my $str_xml = "";
  my $writer  = XML::SAX::Writer->new(Output=>\$str_xml);
  isa_ok($writer,"XML::Filter::BufferText");
  
  #
  
  my $parser = XML::Generator::vCard->new(Handler=>$writer);
  isa_ok($parser,"XML::Generator::vCard");
  
  #
  
  ok($parser->parse_files($vcard),"parsed $vcard");

  ok($str_xml);
}
