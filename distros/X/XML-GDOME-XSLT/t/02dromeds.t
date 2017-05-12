use Test;
BEGIN { plan tests => 6 }
use XML::GDOME::XSLT;
use XML::GDOME;

my $parser = XML::GDOME->new();
ok($parser);

my $doc = $parser->parse_string(<<'EOT');
<?xml version="1.0"?>
  <dromedaries>
    <species name="Camel">
      <humps>1 or 2</humps>
      <disposition>Cranky</disposition>
    </species>
    <species name="Llama">
      <humps>1 (sort of)</humps>
      <disposition>Aloof</disposition>
    </species>
    <species name="Alpaca">
      <humps>(see Llama)</humps>
      <disposition>Friendly</disposition>
    </species>
</dromedaries>
EOT

ok($doc);

my $xslt = XML::GDOME::XSLT->new();
my $style_doc = $parser->parse_string(<<'EOT');
<xsl:stylesheet version="1.0"
      xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
      xmlns:fo="http://www.w3.org/1999/XSL/Format">
<xsl:template match="/">
  <html>
  <head><title>Know Your Dromedaries</title></head>
  <body>
    <table bgcolor="#eeeeee" border="1">
    <tr>
    <th>Species</th>
    <th>No of Humps</th>
    <th>Disposition</th>
    </tr>
    <xsl:for-each select="dromedaries">
      <xsl:apply-templates select="./species" />
    </xsl:for-each>
  </table>
  </body>
  </html>
</xsl:template>

<xsl:template match="species">
  <tr>
  <td><xsl:value-of select="@name" /></td>
  <td><xsl:value-of select="humps" /></td>
  <td><xsl:value-of select="disposition" /></td>
  </tr>
</xsl:template>

</xsl:stylesheet>
EOT

ok($style_doc);

# warn "Style_doc = \n", $style_doc->toString, "\n";

my $stylesheet = $xslt->parse_stylesheet($style_doc);

ok($stylesheet);

my $results = $stylesheet->transform($doc);

ok($results);

my $output = $stylesheet->output_string($results);

ok($output);

# warn "Results:\n", $output, "\n";
