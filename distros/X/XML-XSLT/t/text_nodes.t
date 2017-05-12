# Test xsl:text
# $Id: text_nodes.t,v 1.1 2002/01/09 09:17:40 gellyfish Exp $

use strict;

my $DEBUGGING = 0;

use Test::More tests => 2;


use_ok('XML::XSLT');

# xsl:sort is still broken but I am ignoring that

my $stylesheet =<<EOS;
<xsl:stylesheet version="1.0"
      xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:template match="employees">
  <ul>
    <xsl:apply-templates select="employee">
      <xsl:sort select="name/family"/>
      <xsl:sort select="name/given"/>
    </xsl:apply-templates>
  </ul>
</xsl:template>

<xsl:template match="employee">
  <li>
    <xsl:value-of select="name/given"/>
    <xsl:text> </xsl:text>
    <xsl:value-of select="name/family"/>
  </li>
</xsl:template>
</xsl:stylesheet>
EOS


my $xml =<<EOX;
<employees>
  <employee>
    <name>
      <given>James</given>
      <family>Clark</family>
    </name>
  </employee>
  <employee>
    <name>
      <given>Daniel</given>
      <family>Veillard</family>
    </name>
  </employee>
  <employee>
    <name>
      <given>Michael</given>
      <family>Kay</family>
    </name>
  </employee>
</employees>
EOX

my $expected =<<EOE;
<ul><li>James Clark</li><li>Daniel Veillard</li><li>Michael Kay</li></ul>
EOE

chomp($expected);

eval
{
   my $xslt = XML::XSLT->new($stylesheet, debug => $DEBUGGING);
   

   $xslt->transform(\$xml);

   my $outstr = $xslt->toString();

   warn "$outstr\n" if $DEBUGGING;

   $xslt->dispose();

   die "$outstr ne $expected\n" unless $outstr eq $expected;
};

print $@ if $DEBUGGING;

ok(!$@,'text node preserved');
