# -*- cperl -*-

use strict;
use warnings;

# Should be 4.
use Test::More tests => 4;

use XML::LibXML 1.70;
use XML::LibXSLT;

{
  # test for #41542 - DTD subset disappeare
  # in the source document after the transformation
  my $parser = XML::LibXML->new();
  $parser->validation(1);
  $parser->expand_entities(0);
  my $xml = <<'EOT';
<?xml version="1.0" standalone="no"?>
<!DOCTYPE article [
<!ENTITY foo "FOO">
<!ELEMENT article (#PCDATA)>
]>
<article>&foo;</article>
EOT
  my $doc = $parser->parse_string($xml);

  my $xslt = XML::LibXSLT->new();
  $parser->validation(0);
  my $style_doc = $parser->parse_string(<<'EOX');
<?xml version="1.0" encoding="utf-8"?>
<xsl:transform xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:template match="/">
<out>hello</out>
</xsl:template>
</xsl:transform>
EOX

  # TEST
  is ($doc->toString(), $xml, 'toString() No. 1');
  $xslt->parse_stylesheet($style_doc)->transform($doc);
  # TEST
  is ($doc->toString(), $xml, 'toString() No. 2');

}

{
  # test work-around for rt #29572

  my $parser = XML::LibXML->new();
  my $source = $parser->parse_string(<<'EOT');
<some-xml/>
EOT
  my $style_doc = $parser->load_xml(string=><<'EOT2',no_cdata=>1);
<xsl:stylesheet version="1.0"
      xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:template match="/" >
    <xsl:text
      disable-output-escaping="yes"><![CDATA[<tr>]]></xsl:text>
  </xsl:template>

</xsl:stylesheet>
EOT2
  my $xslt = XML::LibXSLT->new();
  my $stylesheet = $xslt->parse_stylesheet($style_doc);

  my $results = $stylesheet->transform($source);
  # TEST
  ok($results, ' TODO : Add test name');
  my $out = $stylesheet->output_string($results);
  # TEST
  is($out, <<'EOF', '$out is equal to <tr>');
<?xml version="1.0"?>
<tr>
EOF

}
