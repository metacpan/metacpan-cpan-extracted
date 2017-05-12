use strict;

use Test::Simple tests => 6;

use XML::SAX::Writer;
use XML::Filter::Glossary;
use XML::SAX::ParserFactory;

#

eval { require XML::SAX::Expat; };

if ($@) {

  eval { require XML::LibXML::SAX; };

  if ($@) {
    print 
      "$@\n",
      "Can't locate XML::SAX::Expat or XML::LibXML::SAX::Parser.\n",
      "I will use PerlPerl parser instead - this may take a while.\n";
  }

  else { $XML::SAX::ParserPackage = "XML::LibXML::SAX::Parser"; }
}

else { $XML::SAX::ParserPackage = "XML::SAX::Expat"; }

#

eval {
  my $output   = "";
  
  my $writer = XML::SAX::Writer->new(Output=>\$output);
  ok($writer);

  my $glossary = XML::Filter::Glossary->new(Handler=>$writer);
  ok($glossary);

  my $parser = XML::SAX::ParserFactory->parser(Handler=>$glossary);
  ok($parser);

  ok($glossary->register_namespace({Prefix=>"g",
				    NamespaceURI=>"http://www.aaronland.net/glossary",
				    KeywordAttr=>"phrase"}));

  ok($glossary->set_glossary("./t/test.xbel"));

  $parser->parse_uri("./t/test2.html");
  ok(($@) ? 0: 1);

  print $output."\n\n";
};

