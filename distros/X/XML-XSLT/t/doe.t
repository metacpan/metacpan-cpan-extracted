# $Id: doe.t,v 1.2 2001/12/17 11:32:08 gellyfish Exp $
# check disable-output-escaping && the interface

use Test::More tests => 7;
use strict;
use_ok('XML::XSLT');

my $parser = eval { 
my $stylesheet =<<EOS;
<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:template match="doc"><doc><d><xsl:value-of select="p" disable-output-escaping="yes"/></d><xsl:apply-templates/></doc></xsl:template>
<xsl:template match="p"><d><xsl:text disable-output-escaping="yes">&lt;&amp;</xsl:text></d><e><xsl:value-of select="."/></e><e>&lt;<xsl:text>&amp;</xsl:text></e></xsl:template>
</xsl:stylesheet>
EOS
  XML::XSLT->new($stylesheet,warnings => 'Active');
};

ok(! "$@","new from stylsheet text");

ok($parser,"new successful");

eval {
$parser->transform(\<<EOX);
<?xml version="1.0"?><doc><p>&lt;&amp;</p></doc>
EOX
};

ok(!"$@","transform xml");


my $outstr= eval { $parser->toString };

ok(!$@,"toString works");

ok($outstr,"Output is expected");

my $correct='<doc><d><&</d><d><&</d><e>&lt;&amp;</e><e>&lt;&amp;</e></doc>';

ok($outstr eq $correct,"Output is what we expected it to be");
