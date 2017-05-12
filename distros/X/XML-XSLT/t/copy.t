#!/usr/bin/perl
# Test xsl:copy
# $Id: copy.t,v 1.1 2004/02/17 10:06:12 gellyfish Exp $

use Test::More tests => 2;

use strict;
use vars qw($DEBUGGING);

$DEBUGGING = 0;

use_ok('XML::XSLT');


eval
{
  my $stylesheet =<<EOS;
<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:template match="test">
<out><xsl:copy use-attribute-sets="set1"/></out>
</xsl:template>
                                                                                
<xsl:attribute-set name="set1">
  <xsl:attribute name="format">bold</xsl:attribute>
</xsl:attribute-set>
</xsl:stylesheet>
EOS
                                                                                
  my $xml =<<EOX;
<?xml version="1.0"?>
<doc><test>a</test></doc>
EOX
                                                                                
  my $parser = XML::XSLT->new(\$stylesheet,debug => $DEBUGGING);
                                                                                
  $parser->transform(\$xml);
                                                                                
  my $wanted = '<out><test format="bold"/></out>';
  my $outstr =  $parser->toString;
  die "$outstr ne $wanted\n" unless $outstr eq $wanted;
};

ok(!$@,"apply attribute set to xsl:copy");
