use strict;
use warnings;

# Should be 7.
use Test::More tests => 7;

use XML::LibXSLT;
use XML::LibXML;

my $parser = XML::LibXML->new();
my $xslt = XML::LibXSLT->new();

my $source = $parser->parse_string(<<'EOF');
<?xml version="1.0" encoding="UTF-8" ?>
<top>
<next myid="next">NEXT</next>
<bottom myid="last">LAST</bottom>
</top>
EOF

# TEST

ok($source, ' TODO : Add test name');

my $style_doc = $parser->parse_string(<<'EOF');
<?xml version="1.0"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="1.0"
>

<xsl:output method="xml" indent="yes"/>
<xsl:param name="incoming"/>

<xsl:template match="*">
<xsl:value-of select="$incoming"/>
<xsl:text>&#xa;</xsl:text>
      <xsl:copy>
        <xsl:apply-templates select="*"/>
        </xsl:copy>
</xsl:template>

</xsl:stylesheet>
EOF

# TEST
ok($style_doc, ' TODO : Add test name');

my $stylesheet = $xslt->parse_stylesheet($style_doc);

# TEST
ok($stylesheet, ' TODO : Add test name');

my $results = $stylesheet->transform($source,
        'incoming' => "'INCOMINGTEXT'",
#        'incoming' => "'INCOMINGTEXT2'",
        'outgoing' => "'OUTGOINGTEXT'",
        );

# TEST
ok($results, ' TODO : Add test name');

# TEST
ok($stylesheet->output_string($results), ' TODO : Add test name');

my @params = XML::LibXSLT::xpath_to_string('empty' => undef);
$results = $stylesheet->transform($source, @params);
# TEST
ok($results, ' TODO : Add test name');
# TEST
ok($stylesheet->output_string($results), ' TODO : Add test name');

