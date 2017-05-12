use Test;
BEGIN { plan tests => 4 }
use XML::Filter::XSLT;
use XML::SAX::ParserFactory;
use XML::SAX::Writer;

my $xslt = <<EOT;
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:template match="/">
<new>New!</new>
</xsl:template>

</xsl:stylesheet>
EOT

my $output;
my $w = XML::SAX::Writer->new(Output => \$output);
my $f = XML::Filter::XSLT->new(Handler => $w, Source => {String => $xslt});
my $p = XML::SAX::ParserFactory->parser(Handler => $f);

ok($w);
ok($f);
ok($p);

$p->parse_string(<<EOT);
<foo/>
EOT

print "OUTPUT: $output\n";

ok($output);
