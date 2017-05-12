use strict;                     # -*- perl -*-
use warnings;

use Encode;
# Should be 32.
use Test::More tests => 32;

use XML::LibXSLT;
use XML::LibXML;

my $parser = XML::LibXML->new();
# TEST
ok( $parser, ' TODO : Add test name' );

my $xslt = XML::LibXSLT->new();

{
# U+0100 == LATIN CAPITAL LETTER A WITH MACRON
my $doc = $parser->parse_string(<<XML);
<unicode>\x{0100}dam</unicode>
XML
# TEST
ok( $doc, ' TODO : Add test name' );

my $style_doc = $parser->parse_string(<<XSLT);
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="text" encoding="UTF-8"/>
  <xsl:template match="/unicode">
    <xsl:value-of select="."/>
  </xsl:template>
</xsl:stylesheet>
XSLT
# TEST
ok( $style_doc, ' TODO : Add test name' );

my $stylesheet = $xslt->parse_stylesheet($style_doc);
# TEST
ok( $stylesheet, ' TODO : Add test name' );

my $results = $stylesheet->transform($doc);
# TEST
ok( $results, ' TODO : Add test name' );

my $output = $stylesheet->output_string( $results );
# TEST
ok( $output, ' TODO : Add test name' );

# Test that we've correctly converted to characters seeing as the
# output format was UTF-8.

# TEST
ok( Encode::is_utf8($output), ' TODO : Add test name' );
# TEST
is( $output, "\x{0100}dam", ' TODO : Add test name' );

$output = $stylesheet->output_as_chars( $results );
# TEST
ok( Encode::is_utf8($output), ' TODO : Add test name' );
# TEST
is( $output, "\x{0100}dam", ' TODO : Add test name' );

$output = $stylesheet->output_as_bytes( $results );
# TEST
ok( !Encode::is_utf8($output), ' TODO : Add test name' );
# TEST
is( $output, "\xC4\x80dam", ' TODO : Add test name' );
}

# LATIN-2 character 17E - z caron
my $doc = $parser->parse_string(<<XML);
<?xml version="1.0" encoding="UTF-8"?>
<unicode>\x{17E}il</unicode>
XML
# TEST
ok( $doc, ' TODO : Add test name' );

# no encoding: libxslt chooses either an entity or UTF-8
{
  my $style_doc = $parser->parse_string(<<XSLT);
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="text"/>
  <xsl:template match="/unicode">
    <xsl:value-of select="."/>
  </xsl:template>
</xsl:stylesheet>
XSLT
  # TEST
  ok( $style_doc, ' TODO : Add test name' );
  my $stylesheet = $xslt->parse_stylesheet($style_doc);
  # TEST
  ok( $stylesheet, ' TODO : Add test name' );
  my $results = $stylesheet->transform($doc);
  # TEST
  ok( $results, ' TODO : Add test name' );

  my $output = $stylesheet->output_string( $results );
  # TEST
  ok( !Encode::is_utf8($output), ' TODO : Add test name' );
  # TEST
  ok( $output =~ /^(?:&#382;|\xC5\xBE)il/, ' TODO : Add test name' );

  $output = $stylesheet->output_as_chars( $results );
  # TEST
  ok( Encode::is_utf8($output), ' TODO : Add test name' );
  # TEST
  is( $output, "\x{17E}il", ' TODO : Add test name' );
  $output = $stylesheet->output_as_bytes( $results );
  # TEST
  ok( !Encode::is_utf8($output), ' TODO : Add test name' );
  # TEST
  like( $output, qr/^(?:&#382;|\xC5\xBE)il/, ' TODO : Add test name' );
}

# doesn't map to latin-1 so will appear as an entity
{
  my $style_doc = $parser->parse_string(<<XSLT);
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="text" encoding="iso-8859-1"/>
  <xsl:template match="/unicode">
    <xsl:value-of select="."/>
  </xsl:template>
</xsl:stylesheet>
XSLT
  # TEST
  ok( $style_doc, ' TODO : Add test name' );
  my $stylesheet = $xslt->parse_stylesheet($style_doc);
  # TEST
  ok( $stylesheet, ' TODO : Add test name' );
  my $results = $stylesheet->transform($doc);
  # TEST
  ok( $results, ' TODO : Add test name' );
  my $output = $stylesheet->output_string( $results );
  # TEST
  ok( $output, ' TODO : Add test name' );

  # TEST

  ok( !Encode::is_utf8($output), ' TODO : Add test name' );
  # TEST
  is( $output, "&#382;il", ' TODO : Add test name' );

  $output = $stylesheet->output_as_chars( $results );
  # TEST
  ok( Encode::is_utf8($output), ' TODO : Add test name' );
  # TEST
  is( $output, "\x{17E}il", ' TODO : Add test name' );

  $output = $stylesheet->output_as_bytes( $results );
  # TEST
  ok( !Encode::is_utf8($output), ' TODO : Add test name' );
  # TEST
  is( $output, "&#382;il", ' TODO : Add test name' );
}
