# $Id: zeroes.t,v 1.3 2001/12/17 11:32:09 gellyfish Exp $
# check the ``0'' bug && the interface

use Test::More tests => 7;

use strict;
use_ok('XML::XSLT');

my $parser = eval { 
XML::XSLT->new (<<'EOS', warnings => 'Active');
<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:template match="/"><d><xsl:apply-templates/></d></xsl:template>
<xsl:template match="p">0</xsl:template>
<xsl:template match="q"><xsl:text>0</xsl:text></xsl:template>
<xsl:template match="r"><xsl:value-of select="."/></xsl:template>
<xsl:template match="s"><d size="{@size}"><xsl:apply-templates /></d></xsl:template>
</xsl:stylesheet>
EOS
};

ok(! $@,"New from literal stylesheet");
ok($parser,"Parser is a defined value");

eval {
$parser->transform(\<<EOX);
<?xml version="1.0"?><doc><p /><q /><r>0</r><s size="0">0</s></doc>
EOX
};

ok(!$@,"transform a literal XML document");


my $outstr= eval { $parser->toString };

ok(! $@, "toString doesn't die");

ok($outstr,"toString produced output");

my $correct='<d>000<d size="0">0</d></d>';

ok( $correct eq $outstr,"The expected output was produced");
