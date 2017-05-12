use strict;
use Test::More;
use Digest::SHA1 qw (sha1_hex);

plan tests => 13;

SKIP: {

  eval {
    require XML::SAX::Writer;
  };
  
  if ($@) {
    skip("XML::SAX::Writer not installed", 13);
  }
  
  my $msg = "t/example.txt";
  
  use_ok("XML::Generator::RFC822::RDF");
  use_ok("XML::SAX::Writer");
  use_ok("Email::Simple");
  
  ok((-f $msg),"found $msg");
  
  my $txt = undef;
  
  {
    local $/;
    undef $/;
    
    open FH, $msg;
    $txt = <FH>;
    close FH;
  }
      
  ok($txt,"read $msg");
  
  my $email = Email::Simple->new($txt);
  isa_ok($email,"Email::Simple");
  
  my $long_xml = "";
  my $brief_xml = "";
  
  my $writer  = XML::SAX::Writer->new(Output=>\$long_xml);
  isa_ok($writer,"XML::Filter::BufferText");
    
  my $parser = XML::Generator::RFC822::RDF->new(Handler=>$writer);
  isa_ok($parser,"XML::Generator::RFC822::RDF");

  $parser->parse($email);

  ok($long_xml,$long_xml);

  #

  $writer  = XML::SAX::Writer->new(Output=>\$brief_xml);
  isa_ok($writer,"XML::Filter::BufferText");

  $parser = XML::Generator::RFC822::RDF->new(Handler=>$writer,Brief=>1);
  isa_ok($parser,"XML::Generator::RFC822::RDF");

  $parser->parse($email);

  ok($brief_xml,$brief_xml);
  cmp_ok($long_xml,"ne",$brief_xml);
}
