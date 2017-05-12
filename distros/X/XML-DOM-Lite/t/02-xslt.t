# vim:set ft=perl:
use lib 'lib';

use Test::More 'no_plan';
use XML::DOM::Lite qw(Parser :constants);
use XML::DOM::Lite::XSLT;

my $xsl = q{
<xsl:stylesheet>
<xsl:template match="/">
  <xsl:apply-templates select="page/message"/>
</xsl:template>

<xsl:template match="page/message">
  <div style="color:green">
    <xsl:value-of select="."/>
  </div>
</xsl:template>
</xsl:stylesheet>
};

my $xml = q{
<page>
  <message>
    Hello World.
  </message>
</page>
};

my $parser = Parser->new( whitespace => 'strip' );
my $xsldoc = $parser->parse($xsl);
ok($xsldoc);
my $xmldoc  = $parser->parse($xml);
ok($xmldoc);

my $out = XML::DOM::Lite::XSLT->process($xmldoc, $xsldoc);
is($out, q{<div style="color:green">Hello World.</div>});
