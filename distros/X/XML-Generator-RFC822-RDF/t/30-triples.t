use strict;
use Test::More;

plan tests => 17;

SKIP: {

  eval {
    require XML::SAX::Writer;
  };
  
  if ($@) {
    skip("XML::SAX::Writer not installed", 17);
  }
  
  eval { 
    require RDF::Simple::Parser;
  };

  if ($@) {
    skip("RDF::Simple::Parser not installed", 17);
  }

  my $msg = "t/example.txt";
  
  use_ok("XML::Generator::RFC822::RDF");
  use_ok("XML::SAX::Writer");

  use_ok("Email::Simple");
  use_ok("RDF::Simple::Parser");
  
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
  
  my $long_xml  = "";
  my $brief_xml = "";

  my $writer  = XML::SAX::Writer->new(Output=>\$long_xml);
  isa_ok($writer,"XML::Filter::BufferText");
  
  my $parser = XML::Generator::RFC822::RDF->new(Handler=>$writer);
  isa_ok($parser,"XML::Generator::RFC822::RDF");
  
  ok($parser->parse($email),"parsed $msg");

  my $rdf_parser = RDF::Simple::Parser->new(base => "");
  isa_ok($rdf_parser,"RDF::Simple::Parser");
  
  my @triples = $rdf_parser->parse_rdf($long_xml);

  cmp_ok(scalar(@triples),"==",51,"found 51 triples");

  #

  $writer  = XML::SAX::Writer->new(Output=>\$brief_xml);
  isa_ok($writer,"XML::Filter::BufferText");
  
  $parser = XML::Generator::RFC822::RDF->new(Handler=>$writer,Brief=>1);
  isa_ok($parser,"XML::Generator::RFC822::RDF");
  
  ok($parser->parse($email),"parsed $msg");

  $rdf_parser = RDF::Simple::Parser->new(base => "");
  isa_ok($rdf_parser,"RDF::Simple::Parser");
  
  @triples = $rdf_parser->parse_rdf($brief_xml);

  cmp_ok(scalar(@triples),"==",31,"found 31 triples");
}
