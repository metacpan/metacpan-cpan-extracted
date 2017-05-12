use Test;
BEGIN { plan tests => 4 }
use XML::Handler::HTMLWriter;
use XML::SAX;

my $output;
my $writer = XML::Handler::HTMLWriter->new(Output => \$output);
ok($writer);
my $parser = XML::SAX::ParserFactory->parser(Handler => $writer);
ok($parser);

$parser->parse(Source => { SystemId => "testfiles/case_insensitive.xml" });

print $output, "\n";

ok($output);

ok(() = $output =~ /(<br>)/gi, 4);

