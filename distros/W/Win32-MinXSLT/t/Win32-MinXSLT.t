use strict;
use warnings;

use Test::More tests => 2;

BEGIN { use_ok('Win32::MinXSLT') };

{
    my $parser     = Win32::MinXML->new();
    my $xslt       = Win32::MinXSLT->new();

    my $source     = $parser->parse_string(
      q{<?xml version="1.0" encoding="iso-8859-1"?>
        <index>
          <data>aaa</data>
          <data>bbb</data>
          <data>ccc</data>
          <data>ddd</data>
        </index>
        });

    my $style_doc  = $parser->parse_string(
      q{<?xml version="1.0" encoding="iso-8859-1"?>
        <xsl:stylesheet version="1.0"
        xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
          <xsl:output method="xml" indent="yes" encoding="iso-8859-1"/>
          <xsl:template match="/">
            <html>
              <body>
                <title>Test</title>
                Data:
                <hr/>
                <xsl:for-each select="index/data">
                  <p>Test: *** <xsl:value-of select="."/> ***</p>
                </xsl:for-each>
              </body>
            </html>
          </xsl:template>
        </xsl:stylesheet>
        });

    my $stylesheet = $xslt->parse_stylesheet($style_doc);
    my $results    = $stylesheet->transform($source);
    my $output     = $stylesheet->output_string($results);

    $output =~ s{<\? [^?]* \?>}''xms;
    $output =~ s{\s}''xmsg;

    my $expected =
      q{<html><body><title>Test</title>Data:<hr/>}.
      q{<p>Test:***aaa***</p>}.
      q{<p>Test:***bbb***</p>}.
      q{<p>Test:***ccc***</p>}.
      q{<p>Test:***ddd***</p>}.
      q{</body></html>};

    is($output, $expected, 'In-memory transformation works correctly');
}
