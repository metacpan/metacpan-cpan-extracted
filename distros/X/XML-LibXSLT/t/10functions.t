use strict;
use warnings;

# Should be 39.
use Test::More tests => 39;
use XML::LibXSLT;

{
  my $parser = XML::LibXML->new();
  my $xslt = XML::LibXSLT->new();
  # TEST
  ok($parser, '$parser was initted');
  # TEST
  ok($xslt, '$xslt was initted');

  $xslt->register_function('urn:foo' => 'test', sub {
          # TEST*4
          ok(1, 'urn:foo was reached.');
          return $_[1] ?  ($_[0] . $_[1]) : $_[0];
      }
  );
  $xslt->register_function('urn:foo' => 'test2', sub {
          # TEST*2
          is(ref($_[0]), 'XML::LibXML::NodeList', 'First argument is a NodeList');
          ref($_[0])
      }
  );
  $xslt->register_function('urn:foo' => 'test3', sub {
          # TEST*2
          is(scalar(@_), 0, 'No arguments were received.');
          return;
      }
  );

  my $source = $parser->parse_string(<<'EOT');
<?xml version="1.0" encoding="ISO-8859-1"?>
<document></document>
EOT

  my $style = $parser->parse_string(<<'EOT');
<xsl:stylesheet
    version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:foo="urn:foo"
>
<xsl:variable name="FOO"><xsl:call-template name="Foo"/></xsl:variable>
<xsl:template name="Foo"/>

<xsl:template match="/">
  (( <xsl:value-of select="foo:test('Foo', '!')"/> ))
  (( <xsl:value-of select="foo:test('Foo', '!')"/> ))
       <!-- this works -->
     <xsl:value-of select="foo:test(string($FOO))"/>
       <!-- this only works in 1.52 -->
     <xsl:value-of select="foo:test($FOO)"/>
  [[ <xsl:value-of select="foo:test2(/*)"/> ]]
  [[ <xsl:value-of select="foo:test2(/*)"/> ]]
  (( <xsl:value-of select="foo:test3()"/> ))
  (( <xsl:value-of select="foo:test3()"/> ))
</xsl:template>

</xsl:stylesheet>
EOT

  # TEST
  ok($style, '$style is true');
  my $stylesheet = $xslt->parse_stylesheet($style);

  my $results = $stylesheet->transform($source);
  # TEST
  ok($results, '$results is true.');

  # TEST
  like ($stylesheet->output_string($results), qr(Foo!), 'Matches Foo!');
  # TEST
  like ($stylesheet->output_string($results), qr(NodeList), 'Matches NodeList');

  $xslt->register_function('urn:foo' => 'get_list', \&get_nodelist );

  our @words = qw( one two three );

  sub get_nodelist {
    my $nl = XML::LibXML::NodeList->new();
    $nl -> push( map { XML::LibXML::Text->new($_) } @words );
    return $nl;
  }

  $style = $parser->parse_string(<<'EOT');
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:foo="urn:foo">

  <xsl:template match="/">
      <xsl:for-each select='foo:get_list()'>
        <li><xsl:value-of select='.'/></li>
      </xsl:for-each>
  </xsl:template>

</xsl:stylesheet>
EOT

  # TEST
  ok($style, '$style is true - 2');

  $stylesheet = $xslt->parse_stylesheet($style);
  # TEST:$n=5;
  for my $n (1..5) {
    $results = $stylesheet->transform($source);

    # TEST*$n
    ok($results, '$results is true - 2 (' . $n . ')');
    # TEST*$n
    like($stylesheet->output_string($results),
        qr(<li>one</li>),
        'Matches li-one - ' . $n
    );
    # TEST*$n
    like (
        $stylesheet->output_string($results),
        qr(<li>one</li><li>two</li><li>three</li>),
        'Output matches multiple lis - ' . $n
    );
  }
}

{
  # testcase by Elizabeth Mattijsen
  my $parser   = XML::LibXML->new;
  my $xsltproc = XML::LibXSLT->new;

  my $xml  = $parser->parse_string( <<'XML' );
<html><head/></html>
XML
  my $xslt = $parser->parse_string( <<'XSLT' );
<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:foo="http://foo"
  version="1.0">
<xsl:template match="/html">
   <html>
     <xsl:apply-templates/>
   </html>
</xsl:template>
<xsl:template match="/html/head">
  <head>
   <xsl:copy-of select="foo:custom()/foo"/>
   <xsl:apply-templates/>
  </head>
</xsl:template>
</xsl:stylesheet>
XSLT

  my $aux = <<'XML';
<bar>
  <y><foo>1st</foo></y>
  <y><foo>2nd</foo></y>
</bar>
XML
  {
    XML::LibXSLT->register_function(
      ('http://foo', 'custom') => sub { $parser->parse_string( $aux )->findnodes('//y') }
     );
    my $stylesheet = $xsltproc->parse_stylesheet($xslt);
    my $result = $stylesheet->transform($xml);
    # the behavior has changed in some version of libxslt
    my $expect = qq(<html xmlns:foo="http://foo"><head><foo>1st</foo><foo>2nd</foo></head></html>\n);
    # TEST
    like ($result->serialize,
        qr{(\Q<?xml version="1.0"?>\n\E)?\Q$expect\E},
        'Results serialize matches text.'
    );
  }
  {
    XML::LibXSLT->register_function(
      ('http://foo', 'custom') => sub { $parser->parse_string( $aux )->findnodes('//y')->[0]; });
    my $stylesheet = $xsltproc->parse_stylesheet($xslt);
    my $result = $stylesheet->transform($xml);
    my $expect = qq(<html xmlns:foo="http://foo"><head><foo>1st</foo></head></html>\n);
    # TEST
    like (
        $result->serialize,
        qr{(\Q<?xml version="1.0"?>\n\E)?\Q$expect\E},
        'Results serialize matches text - 2.'
    );
  }
}

{
  my $parser   = XML::LibXML->new;
  my $xsltproc = XML::LibXSLT->new;
   my $xslt = $parser->parse_string( <<'XSLT' );
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:x="http://x/x"
  version="1.0">
<xsl:namespace-alias stylesheet-prefix="x" result-prefix="#default"/>
<xsl:template match="/">
   <out>
     <xsl:copy-of select="x:test(.)"/>
   </out>
</xsl:template>
</xsl:stylesheet>
XSLT
  $xsltproc->register_function(
    ("http://x/x", 'test') => sub { $_[0][0]->findnodes('//b[parent::a]') }
   );
  my $stylesheet = $xsltproc->parse_stylesheet($xslt);
  my $result = $stylesheet->transform($parser->parse_string( <<'XML' ));
<a><b><b/></b><b><c/></b></a>
XML
  # TEST
  is ($result->serialize,
      qq(<?xml version="1.0"?>\n<out><b><b/></b><b><c/></b></out>\n),
      'result is right.'
  );
}

{
  my $callbackNS = "http://x/x";

  my $p = XML::LibXML->new;
  my $xsltproc = XML::LibXSLT->new;
  $xsltproc->register_function(
    $callbackNS,
    "some_function",
    sub {
      my($format) = @_;
      return $format;
    }
   );
  $xsltproc->register_function(
    $callbackNS,
    "some_function2",
    sub {
      my($format) = @_;
      return $format->[0];
    }
   );

  my $xsltdoc = $p->parse_string(<<'EOF');
<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0"
     xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
     xmlns:x="http://x/x"
>

<xsl:template match="root">
  <root>
    <xsl:value-of select="x:some_function(@format)" />
    <xsl:text>,</xsl:text>
    <xsl:value-of select="x:some_function(.)" />
    <xsl:text>,</xsl:text>
    <xsl:value-of select="x:some_function(processing-instruction())" />
    <xsl:text>,</xsl:text>
    <xsl:value-of select="x:some_function(text())" />
    <xsl:text>;</xsl:text>

    <xsl:value-of select="x:some_function2(@format)" />
    <xsl:text>,</xsl:text>
    <xsl:value-of select="x:some_function2(.)" />
    <xsl:text>,</xsl:text>
    <xsl:value-of select="x:some_function2(processing-instruction())" />
    <xsl:text>,</xsl:text>
    <xsl:value-of select="x:some_function2(text())" />
    <xsl:text>;</xsl:text>
    <xsl:for-each select="x:some_function(node())">
      <xsl:value-of select="." />
    </xsl:for-each>
  </root>
</xsl:template>

</xsl:stylesheet>
EOF

  my $doc = $p->parse_string(<<EOF);
<root format="foo">bar<?baz bak?><y>zzz</y></root>
EOF

  my $stylesheet = $xsltproc->parse_stylesheet($xsltdoc);
  my $result = $stylesheet->transform($doc);
  my $val = $result->findvalue("/root");
  # TEST
  ok ($val, 'val is true.');
  # TEST
  is ($val, "foo,barzzz,bak,bar;foo,barzzz,bak,bar;barbakzzz",
      'val has the right value.')
    or print $stylesheet->output_as_bytes($result);

}

{
  my $ns = "http://foo";

  my $p = XML::LibXML->new;
  my $xsltproc = XML::LibXSLT->new;

  my $xsltdoc = $p->parse_string(<<EOF);
<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0"
     xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
     xmlns:foo="$ns"
>

<xsl:template match="root">
<root>
<xsl:value-of select="foo:bar(10)" />
</root>
</xsl:template>

</xsl:stylesheet>
EOF

  my $doc = $p->parse_string(<<EOF);
<root></root>
EOF

  my $stylesheet = $xsltproc->parse_stylesheet($xsltdoc);
  $stylesheet->register_function($ns, "bar", sub { return $_[0] * 2 });
  my $result = $stylesheet->transform($doc);
  my $val = $result->findvalue("/root");
  # TEST
  is ($val, 20, "contextual register_function" );
}

{
  my $ns = "http://foo";

  my $p = XML::LibXML->new;
  my $xsltproc = XML::LibXSLT->new;

  my $xsltdoc = $p->parse_string(<<EOF);
<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0"
     xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
     xmlns:foo="$ns"
	 extension-element-prefixes="foo"
>

<xsl:template match="root">
<root>
<foo:bar value="10"/>
</root>
</xsl:template>

</xsl:stylesheet>
EOF

  my $doc = $p->parse_string(<<EOF);
<root></root>
EOF

  my $stylesheet = $xsltproc->parse_stylesheet($xsltdoc);
  $stylesheet->register_element($ns, "bar", sub {
	  return XML::LibXML::Text->new( $_[2]->getAttribute( "value" ) );
  });
  my $result = $stylesheet->transform($doc);
  my $val = $result->findvalue("/root");
  # TEST
  is ($val, 10, "contextual register_element");
}

{
    # GNOME Bugzilla bug #562302
    my $parser = new XML::LibXML;
    my $xslt = new XML::LibXSLT;

    # registering function
    XML::LibXSLT->register_function("urn:perl", 'cfg', sub {
        return $parser->parse_string('<xml_storage/>');
    });

    # loading and parsing stylesheet
    my $style_doc = $parser->parse_string(<<'EOF');
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exslt="http://exslt.org/common"
    xmlns:perl="urn:perl"
    exclude-result-prefixes="exslt perl">

<xsl:variable name="xml_storage" select="perl:cfg()/xml_storage" />

<xsl:variable name="page-data-tree">
    <title><xsl:value-of select="$xml_storage"/></title>
    <crumbs>
        <page><url>hello</url></page>
        <page><url>bye</url></page>
    </crumbs>
</xsl:variable>
<xsl:variable name="page-data" select="exslt:node-set($page-data-tree)" />

<xsl:template match="/">
    <result><xsl:copy-of select="$xml_storage"/></result>
</xsl:template>

</xsl:stylesheet>
EOF

    my $stylesheet = $xslt->parse_stylesheet($style_doc);

    # performing transform
    my $source = XML::LibXML::Document->new;
    my $results = $stylesheet->transform($source);

    my $string = $stylesheet->output_string($results);
    my $expected = <<'EOF';
<?xml version="1.0"?>
<result><xml_storage/></result>
EOF
    # TEST
    is ($string, $expected, 'GNOME Bugzilla bug #562302');
}

# TEST
ok(1, 'Reached here.');
