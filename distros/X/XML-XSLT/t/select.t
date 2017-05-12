#!/usr/bin/perl
# Test select/match with various special paths
# $Id: select.t,v 1.2 2004/02/19 08:38:41 gellyfish Exp $

use Test::More tests => 4;

use strict;
use vars qw($DEBUGGING);

$DEBUGGING = 0;

use_ok('XML::XSLT');


eval
{
  my $stylesheet =<<EOS;
<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:template match="doc">
    <xsl:apply-templates select="processing-instruction()"/>
</xsl:template>
                                                                                
<xsl:template match="processing-instruction()">
  <out>
  <xsl:value-of select="."/>
  </out>
</xsl:template>
</xsl:stylesheet>
EOS
                                                                                
  my $xml =<<EOX;
<?xml version="1.0"?>
<doc>
<?PITarget Processing-Instruction 1 type='text/xml'?>
</doc>
EOX
                                                                                
  my $parser = XML::XSLT->new(\$stylesheet,debug => $DEBUGGING);
                                                                                
  $parser->transform(\$xml);
                                                                                
  my $wanted = q%<out>Processing-Instruction 1 type='text/xml'</out>%;
  my $outstr =  $parser->toString;
  die "$outstr ne $wanted\n" unless $outstr eq $wanted;
};

ok(!$@,"select single processing-instruction()");

eval
{
  my $stylesheet =<<EOS;
<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:template match="doc">
    <xsl:apply-templates select="comment()"/>
</xsl:template>
                                                                                
<xsl:template match="comment()">
  <out>
  <xsl:value-of select="."/>
  </out>
</xsl:template>
</xsl:stylesheet>
EOS
                                                                                
  my $xml =<<EOX;
<?xml version="1.0"?>
<doc>
<!-- TEST COMMENT -->
</doc>
EOX
                                                                                
  my $parser = XML::XSLT->new(\$stylesheet,debug => $DEBUGGING);
                                                                                
  $parser->transform(\$xml);
                                                                                
  my $wanted = q%<out> TEST COMMENT </out>%;
  my $outstr =  $parser->toString;
  die "$outstr ne $wanted\n" unless $outstr eq $wanted;
};

ok(!$@,"select single comment()");

eval
{
  my $stylesheet =<<EOS;
<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:template match="doc">
    <xsl:apply-templates select="text()"/>
</xsl:template>
                                                                                
<xsl:template match="text()">
  <out>
   <xsl:value-of select="."/>
  </out>
</xsl:template>
</xsl:stylesheet>
EOS
                                                                                
  my $xml =<<EOX;
<?xml version="1.0"?>
<doc>TEST TEXT</doc>
EOX
                                                                                
  my $parser = XML::XSLT->new(\$stylesheet,debug => $DEBUGGING);
                                                                                
  $parser->transform(\$xml);
                                                                                
  my $wanted = q%<out>TEST TEXT</out>%;
  my $outstr =  $parser->toString;
  die "$outstr ne $wanted\n" unless $outstr eq $wanted;
};

ok(!$@,"select text()");
