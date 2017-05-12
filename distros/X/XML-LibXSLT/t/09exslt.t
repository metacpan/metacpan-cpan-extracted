use strict;
use warnings;

use Test::More;

use XML::LibXSLT;
use XML::LibXML;

if (not XML::LibXSLT::HAVE_EXSLT()) {
    plan skip_all => "this test requires XML::LibXSLT to be compiled with libexslt"
}
else {
    # Should be 6.
    plan tests => 6;
}

my $parser = XML::LibXML->new();
# TEST
ok($parser, '$parser was initted.');

my $doc = $parser->parse_string(<<'EOT');
<?xml version="1.0"?>

<doc>

</doc>
EOT

# TEST
ok($doc, '$doc is true.');

my $xslt = XML::LibXSLT->new();
my $style_doc = $parser->parse_string(<<'EOT');
<?xml version="1.0"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:str="http://exslt.org/strings"
    exclude-result-prefixes="str">

<xsl:template match="/">
<out>;
 str:tokenize('2001-06-03T11:40:23', '-T:')
 <xsl:copy-of select="str:tokenize('2001-06-03T11:40:23', '-T:')"/>;
 str:tokenize('date math str')
 <xsl:copy-of select="str:tokenize('date math str')"/>;
</out>
</xsl:template>

</xsl:stylesheet>
EOT

# TEST

ok($style_doc, '$style_doc is true.');

# warn "Style_doc = \n", $style_doc->toString, "\n";

my $stylesheet = $xslt->parse_stylesheet($style_doc);

# TEST
ok($stylesheet, '$stylesheet is true.');

my $results = $stylesheet->transform($doc);

# TEST
ok($results, '$results is true.');

my $output = $stylesheet->output_string($results);

# TEST
ok($output, '$output is true.');

# warn "Results:\n", $output, "\n";
