# Test that attributes work
# $Id: attributes.t,v 1.4 2004/02/17 10:44:29 gellyfish Exp $

use Test::More tests => 5;

use strict;
use vars qw($DEBUGGING);

$DEBUGGING = 0;

use_ok('XML::XSLT');

eval
{
   my $stylesheet = <<EOS;
<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:template match="doc"><doc><xsl:apply-templates/></doc></xsl:template>
<xsl:template match="p">
<p><xsl:attribute name="test"><xsl:text>foo</xsl:text></xsl:attribute><xsl:text>Foo</xsl:text></p>
</xsl:template>
</xsl:stylesheet>
EOS

   my $xml =<<EOX;
<?xml version="1.0"?>
<doc><p>Some Random text</p></doc>
EOX

   my $expected = qq{<doc><p test="foo">Foo</p></doc>};
   my $parser = XML::XSLT->new(\$stylesheet,debug => $DEBUGGING);

   $parser->transform(\$xml);

   my $outstr = $parser->toString();

   warn "$outstr\n" if $DEBUGGING;

    $parser->dispose();

   die "$outstr ne $expected\n" unless $outstr eq $expected;
};

ok(!$@, "xsl:attribute works");

eval
{
   my $stylesheet =<<EOS;
<?xml version="1.0"?>
<xsl:transform xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
               version="1.0">

  <xsl:output method="xml"
       encoding="ISO-8859-1"
       indent="yes"/>

  <xsl:attribute-set name="outer-table">
     <xsl:attribute name="summary">
        <xsl:text>This is a summary</xsl:text>
     </xsl:attribute>
  </xsl:attribute-set>
  <xsl:template match="doc"><doc><xsl:apply-templates /></doc></xsl:template>

  <xsl:template match="p">
    <xsl:element name="p" use-attribute-sets="outer-table">
       <xsl:text>Foo</xsl:text>
    </xsl:element>
</xsl:template>
</xsl:transform>
EOS

  my $xml =<<EOX;
<?xml version="1.0"?>
<doc><p>Some Random text</p></doc>
EOX

  my $parser = XML::XSLT->new(\$stylesheet,debug => $DEBUGGING);

  $parser->transform(\$xml);

  
  my $outstr =  $parser->toString() ;

  my $expected =<<EOE;
<doc><p summary="This is a summary">Foo</p></doc>
EOE

  chomp($expected);

  warn "$outstr\n" if $DEBUGGING;
  die "$outstr ne $expected\n" unless $outstr eq $expected;

  $parser->dispose();
};

warn "$@\n" if $DEBUGGING;

ok(!$@, "attribute-set in element");

eval
{
   my $stylesheet =<<EOS;
<?xml version="1.0"?>
<xsl:transform xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
               version="1.0">

  <xsl:output method="xml"
       encoding="ISO-8859-1"
       indent="yes"/>

<xsl:attribute-set name="set2" use-attribute-sets="set3">
  <xsl:attribute name="text-decoration">underline</xsl:attribute>
</xsl:attribute-set>
                                                                                
<xsl:attribute-set name="set1" use-attribute-sets="set2">
  <xsl:attribute name="color">black</xsl:attribute>
</xsl:attribute-set>
                                                                                
<xsl:attribute-set name="set3">
  <xsl:attribute name="font-size">14pt</xsl:attribute>
</xsl:attribute-set>


  <xsl:template match="p">
    <xsl:element name="p" use-attribute-sets="set1">
       <xsl:text>Foo</xsl:text>
    </xsl:element>
</xsl:template>
</xsl:transform>
EOS

  my $xml =<<EOX;
<?xml version="1.0"?>
<doc><p>Some Random text</p></doc>
EOX

  my $parser = XML::XSLT->new(\$stylesheet,debug => $DEBUGGING);

  $parser->transform(\$xml);

  
  my $outstr =  $parser->toString() ;

  my $expected =<<EOE;
<p(?: font-size="14pt"| color="black"| text-decoration="underline"){3}>Foo</p>
EOE

  chomp($expected);

  warn "$outstr\n" if $DEBUGGING;
  die "$outstr ne $expected\n" unless $outstr =~ /$expected/;

  $parser->dispose();
};

warn "$@\n" if $DEBUGGING;

ok(!$@, "nested attribute-sets");

eval
{
   my $stylesheet =<<EOS;
<xsl:stylesheet
  version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:axsl="http://www.w3.org/1999/XSL/TransformAlias">

<xsl:template match="doc">
<doc>
<xsl:attribute name="xmlns:xsl" namespace="whatever">http://www.w3.org/1999/XSL/Transform</xsl:attribute>
<xsl:attribute name="attr">value</xsl:attribute>
</doc>
</xsl:template>

</xsl:stylesheet>
EOS

  my $xml = '<doc/>';

  my $parser = XML::XSLT->new(\$stylesheet,debug => $DEBUGGING);

  $parser->transform(\$xml);

  
  my $outstr =  $parser->toString() ;



  warn "$outstr\n" if $DEBUGGING;
  die "$outstr contains xmlns declaration\n" if $outstr =~ /xmlns:xsl/ ;

  $parser->dispose();

};

warn "$@\n" if $DEBUGGING;

ok(!$@, "do not output namespace declaration");
