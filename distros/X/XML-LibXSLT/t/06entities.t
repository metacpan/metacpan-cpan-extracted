use strict;
use warnings;

use Test::More tests => 2;

use XML::LibXML;
use XML::LibXSLT;

my $parser = XML::LibXML->new();
my $xslt = XML::LibXSLT->new();

$parser->expand_entities(1);

my $source = $parser->parse_string(qq{<?xml version="1.0" encoding="UTF-8"?>
<root>foo</root>});
my $style_doc = $parser->parse_string('<?xml version="1.0" encoding="ISO-8859-1"?>
<!DOCTYPE stylesheet [
<!ENTITY ouml   "&#246;">
]>

<xsl:stylesheet
     xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
     version="1.0">
 <xsl:output method="xml" />

 <xsl:template match="/">
  <out>foo&ouml;bar</out>
 </xsl:template>

</xsl:stylesheet>
');


my $stylesheet = $xslt->parse_stylesheet($style_doc);

my $results = $stylesheet->transform($source);

my $tostring = $results->toString;

# TEST
like ($tostring, qr/foo(?:.|&#xF6;)bar/i, '$tostring matches entity.');

my $content = $stylesheet->output_string($results);

# libxml2-2.6.16/libxslt-1.1.9 will produce a character entity
# latest versions give a UTF-8 encoded character

# TEST
like ($content, qr/foo(?:&#xF6;|\xC3\xB6)bar/i, '$content matches entity.');

