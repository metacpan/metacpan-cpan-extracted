
use strict;
use warnings;

# Should be 12.
use Test::More tests => 12;

use XML::LibXSLT;
use XML::LibXML;

# this test is here because Mark Cox found a segfault
# that occurs when parse_stylesheet is immediately followed
# by a transform()

my $parser = XML::LibXML->new();
my $xslt = XML::LibXSLT->new();
# TEST
ok($parser, ' TODO : Add test name'); # TEST
 ok($xslt, ' TODO : Add test name');
my $source = $parser->parse_file('example/1.xml');
# TEST
ok($source, ' TODO : Add test name');

my ($out1, $out2);

{
my $style_doc = $parser->parse_file('example/1.xsl');
my $stylesheet = $xslt->parse_stylesheet($style_doc);
my $results = $stylesheet->transform($source);
$out1 = $stylesheet->output_string($results);
# TEST
ok($out1, ' TODO : Add test name');
}

{
$source = $parser->parse_file('example/2.xml');
# TEST
ok($source, ' TODO : Add test name');
my $style_doc = $parser->parse_file('example/2.xsl');
my $stylesheet = $xslt->parse_stylesheet($style_doc);
my $results = $stylesheet->transform($source);
# TEST
ok($stylesheet->media_type, ' TODO : Add test name');
# TEST
ok($stylesheet->output_method, ' Test existence of output method');
$out2 = $stylesheet->output_string($results);
# TEST
ok($out2, ' TODO : Add test name');
}

{
  my $style_doc = $parser->parse_file('example/1.xsl');
  my $stylesheet = $xslt->parse_stylesheet($style_doc);
  my $results = $stylesheet->transform_file('example/1.xml');
  my $out = $stylesheet->output_string($results);
  # TEST
  ok ($out, ' TODO : Add test name' );
  # TEST
  is ($out1, $out, ' TODO : Add test name' );
}

{
  my $style_doc = $parser->parse_file('example/2.xsl');
  my $stylesheet = $xslt->parse_stylesheet($style_doc);
  my $results = $stylesheet->transform_file('example/2.xml');
  my $out = $stylesheet->output_string($results);
  # TEST
  ok( $out, ' TODO : Add test name' );
  # TEST
  is ($out2, $out, ' TODO : Add test name' );
}
