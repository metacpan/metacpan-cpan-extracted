use Test;
BEGIN { plan tests => 5 }
use XML::Handler::HTMLWriter;
use XML::SAX;

my $output;
my $writer = XML::Handler::HTMLWriter->new(Output => \$output);
ok($writer);
my $parser = XML::SAX::ParserFactory->parser(Handler => $writer);
ok($parser);

$parser->parse(Source => { SystemId => "testfiles/script_and_style.xml" });

print $output, "\n";

ok($output);

ok($output, qr((?s)<script>.*here < 4.*</script>));
ok($output, qr((?s)<style>.*&(?!amp;).*</style>));

