# Test miscellaneous features
# $Id: features.t,v 1.1 2001/12/17 11:32:09 gellyfish Exp $

use strict;
use Test::More tests => 3;

use_ok('XML::XSLT');

my $sheet =<<EOS;
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform">   
   <xsl:template match="/">
      <xsl:message terminate="yes">
         <xsl:text>Prepare to die!</xsl:text>
      </xsl:message>
  </xsl:template>
</xsl:stylesheet>
EOS

my $parser;

eval
{
   $parser = XML::XSLT->new(\$sheet);
   die unless $parser;
};

ok(! $@, "Testing parse of <xsl:message> and <xsl:text>");

my $xml = '<data>foo</data>';

SKIP:
{
  skip("Message not implemented",1);
  eval
  {
    $parser->transform($xml);
  }; 
  ok($@,"Message");
}
