use Test;
BEGIN { plan tests => 5 }
use XML::Handler::HTMLWriter;
use XML::SAX;

my $output;
my $writer = XML::Handler::HTMLWriter->new(Output => \$output);
ok($writer);
my $parser = XML::SAX::ParserFactory->parser(Handler => $writer);
ok($parser);

$parser->parse(Source => { SystemId => "testfiles/meta_tag.xml" });

print $output, "\n";

ok($output);

ok($output, qr((?i)<head><meta http-equiv));

$writer = XML::Handler::HTMLWriter->new(Output => \$output, EncodeTo => "ISO-8859-1");
$parser = XML::SAX::ParserFactory->parser(Handler => $writer);

$parser->parse(Source => { SystemId => "testfiles/meta_tag.xml" });

print $output, "\n";

ok($output, qr/(?i)ISO-8859-1/);

