use Test;
BEGIN { plan tests => 5 }
use XML::Handler::HTMLWriter;
use XML::SAX;

my $output;
my $writer = XML::Handler::HTMLWriter->new(Output => \$output);
ok($writer);
my $parser = XML::SAX::ParserFactory->parser(Handler => $writer);
ok($parser);

$parser->parse(Source => { SystemId => "testfiles/non_html.xml" });

print $output, "\n";

ok($output);

ok($output, qr/<NotAnHTMLTag\s*(\/>|<\/NotAnHTMLTag>)/);
ok($output, qr/<Another_Non_HTML_Tag>Content<br><\/Another_Non_HTML_Tag>/);

