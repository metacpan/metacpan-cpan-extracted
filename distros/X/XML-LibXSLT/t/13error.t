use strict;
use warnings;

# Should be 28.
use Test::More tests => 28;

$|=1;

use XML::LibXSLT;
# TEST
ok(1, ' TODO : Add test name');

my $bad_xsl1 = 'example/bad1.xsl';
my $bad_xsl2 = 'example/bad2.xsl';
my $bad_xsl3 = 'example/bad3.xsl';
my $fatal_xsl = 'example/fatal.xsl';
my $nonfatal_xsl = 'example/nonfatal.xsl';
my $good_xsl = 'example/1.xsl';
my $good_xml = 'example/1.xml';
my $bad_xml  = 'example/bad2.xsl';

my $xslt = XML::LibXSLT->new;
# TEST
ok($xslt, ' TODO : Add test name');

{
  my $stylesheet = XML::LibXML->new->parse_file($bad_xsl1);
  undef $@;
  eval { $xslt->parse_stylesheet($stylesheet) };
  # TEST
  ok( $@, ' TODO : Add test name' );
}

{
  undef $@;
  eval { XML::LibXML->new->parse_file($bad_xsl2) };
  # TEST
  ok( $@, ' TODO : Add test name' );
}

{
  my $stylesheet = XML::LibXML->new->parse_file($good_xsl);
  # TEST
  ok( $stylesheet, ' TODO : Add test name' );
  my $parsed = $xslt->parse_stylesheet( $stylesheet );
  # TEST
  ok( $parsed, ' TODO : Add test name' );
  undef $@;
  eval { $parsed->transform_file( $bad_xml ); };
  # TEST
  ok( $@, ' TODO : Add test name' );
}

{
  my $stylesheet = XML::LibXML->new->parse_file($nonfatal_xsl);
  # TEST
  ok( $stylesheet, ' TODO : Add test name' );
  my $parsed = $xslt->parse_stylesheet( $stylesheet );
  # TEST
  ok( $parsed, ' TODO : Add test name' );
  undef $@;
  my $warn;
  local $SIG{__WARN__} = sub { $warn = shift; };
  eval { $parsed->transform_file( $good_xml ); };
  # TEST
  ok( !$@, ' TODO : Add test name' );
  # TEST
  is( $warn , "Non-fatal message.\n", ' TODO : Add test name' );
}

{
  my $parser = XML::LibXML->new;
  my $stylesheet = $parser->parse_file($bad_xsl3);
  # TEST
  ok( $stylesheet, ' TODO : Add test name' );
  my $parsed = $xslt->parse_stylesheet( $stylesheet );
  # TEST
  ok( $parsed, ' TODO : Add test name' );
  undef $@;
  eval { $parsed->transform_file( $good_xml ); };
  # TEST
  ok( $@, ' TODO : Add test name' );
  my $dom = $parser->parse_file( $good_xml );
  # TEST
  ok( $dom, ' TODO : Add test name' );
  undef $@;
  eval { $parsed->transform( $dom ); };
  # TEST
  ok( $@, ' TODO : Add test name' );
}

{
  my $parser = XML::LibXML->new;
  my $stylesheet = $parser->parse_file($fatal_xsl);
  # TEST
  ok( $stylesheet, ' TODO : Add test name' );
  my $parsed = $xslt->parse_stylesheet( $stylesheet );
  # TEST
  ok( $parsed, ' TODO : Add test name' );
  undef $@;
  eval { $parsed->transform_file( $good_xml ); };
  # TEST
  ok( $@, ' TODO : Add test name' );
  my $dom = $parser->parse_file( $good_xml );
  # TEST
  ok( $dom, ' TODO : Add test name' );
  undef $@;
  eval { $parsed->transform( $dom ); };
  # TEST
  ok( $@, ' TODO : Add test name' );
}

{
my $parser = XML::LibXML->new();
# TEST
ok( $parser, ' TODO : Add test name' );

my $doc = $parser->parse_string(<<XML);
<doc/>
XML
# TEST
ok( $doc, ' TODO : Add test name' );

my $xslt = XML::LibXSLT->new();
my $style_doc = $parser->parse_string(<<XSLT);
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:template match="/">
    <xsl:value-of select="\$foo"/>
  </xsl:template>
</xsl:stylesheet>
XSLT
# TEST
ok( $style_doc, ' TODO : Add test name' );

my $stylesheet = $xslt->parse_stylesheet($style_doc);
# TEST
ok( $stylesheet, ' TODO : Add test name' );

my $results;
eval { $results = $stylesheet->transform($doc); };

my $E = $@;
# TEST
ok( $E, ' TODO : Add test name' );

# TEST
like ( $E,
    qr/unregistered variable foo|variable 'foo' has not been declared/i,
    'Exception matches.' );
# TEST
like ( $E, qr/element value-of/, 'Exception matches "element value-of"' );
}
