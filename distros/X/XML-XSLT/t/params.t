# $Id: params.t,v 1.2 2001/12/17 11:32:09 gellyfish Exp $
# check params && the interface

use Test::More tests => 7;
use strict;
use_ok('XML::XSLT');

my $parser = eval { 
XML::XSLT->new (<<'EOS', warnings => 'Active');
<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:template match="a"><xsl:apply-templates>
  <xsl:with-param name="param1">value1</xsl:with-param>
</xsl:apply-templates></xsl:template>

<xsl:template match="b"><xsl:param name="param1">undefined</xsl:param>[ param1=<xsl:value-of select="$param1"/> ]</xsl:template>

</xsl:stylesheet>
EOS
};

ok(! $@,"New from literal stylesheet");
ok($parser,"Parser is defined");

eval {
$parser->transform(\<<EOX);
<?xml version="1.0"?><doc><a><b/></a><b/></doc>
EOX
};

ok(! $@,"transform from on literal XML");


my $outstr= eval { $parser->toString };

ok(! $@, "toString works");

ok($outstr,"toString created output");

my $correct='[ param1=value1 ][ param1=undefined ]';

ok( $correct eq $outstr,"Output is as expected");
