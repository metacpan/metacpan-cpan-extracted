use Test;
BEGIN { plan tests => 5 }
use XML::Handler::HTMLWriter;
use XML::SAX;

my $output;
my $writer = XML::Handler::HTMLWriter->new(Output => \$output);
ok($writer);
my $parser = XML::SAX::ParserFactory->parser(Handler => $writer);
ok($parser);

$parser->parse(Source => { SystemId => "testfiles/namespace.xml" });

print $output, "\n";

ok($output);

ok($output, qr/<ns:foo xmlns:ns=(["'])http:\/\/www.example.com\/foo\1>/);
ok($output, qr/<default xmlns=(["'])http:\/\/www.example.com\/default\1/);

