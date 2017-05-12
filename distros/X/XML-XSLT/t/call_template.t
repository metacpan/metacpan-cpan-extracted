# $Id: call_template.t,v 1.1 2002/01/08 10:11:47 gellyfish Exp $
# Check call-template

use strict;

my $DEBUGGING = 0;

use Test::More tests => 2;


use_ok('XML::XSLT');

my $stylesheet =<<EOS;
<xsl:stylesheet version="1.0"
      xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:template match="doc">
    <xsl:call-template name="docfound"/>
</xsl:template>

<xsl:template name="docfound">
<xsl:text>doc found</xsl:text>
</xsl:template>
</xsl:stylesheet>
EOS


my $xml = '<doc><div></div></doc>';

eval
{
   my $xslt = XML::XSLT->new($stylesheet, debug => $DEBUGGING);
   
   my $expected = 'doc found';

   $xslt->transform(\$xml);

   my $outstr = $xslt->toString();

   $outstr =~ s/^\s+//;
   $outstr =~ s/\s+$//;
   warn "$outstr\n" if $DEBUGGING;

   $xslt->dispose();

   die "$outstr ne $expected\n" unless $outstr eq $expected;
};


ok(!$@,'Call template');
