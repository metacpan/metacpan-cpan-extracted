use Test;
BEGIN { plan tests => 5 }
use XML::Handler::HTMLWriter;
use XML::SAX;

my $output;
my $writer = XML::Handler::HTMLWriter->new(Output => \$output);
ok($writer);
my $parser = XML::SAX::ParserFactory->parser(Handler => $writer);
ok($parser);

$parser->parse(Source => { SystemId => "testfiles/lt_attribs.xml" });

print $output, "\n";

ok($output);

ok($output, qr(<img alt=(["'])<< text >>\1>));
ok($output, qr(<non_html attrib=(["'])&lt;tag));
