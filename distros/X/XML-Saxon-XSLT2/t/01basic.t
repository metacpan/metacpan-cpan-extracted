## skip Test::Tabs
use Test::More tests => 4;
use XML::Saxon::XSLT2;

my $xslt = <<'XSLT';
<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0">
<xsl:param name="bar"/>
<xsl:template match="/">
<xsl:variable name="allauthors">
    <authors foo="{$bar}">
        <xsl:for-each select="/books/book">
				<xsl:sort select="@author"/>
            <author id="{@author}"/>
        </xsl:for-each>
    </authors>
</xsl:variable>
<xsl:copy-of select="$allauthors"/>
</xsl:template>
</xsl:stylesheet>
XSLT

my $input = <<'XML';
<?xml version="1.0" encoding="UTF-8"?>
<books>
    <book name="Programming Ruby"
      author="Dave Thomas"/>
    <book name="Code Generation in Action"
      author="Jack Herrington"/>
    <book name="Pragmatic Programmer"
      author="Dave Thomas"/>
</books>
XML

my $transformation = XML::Saxon::XSLT2->new($xslt);
$transformation->parameters('bar' => [date=>'2010-02-28']);
my $output = $transformation->transform_document($input, 'xml');

is($output->documentElement->getAttribute('foo'), '2010-02-28');

my @authors = $output->getElementsByTagName('author');

is($authors[0]->getAttribute('id'), 'Dave Thomas');
is($authors[1]->getAttribute('id'), 'Dave Thomas');
is($authors[2]->getAttribute('id'), 'Jack Herrington');
