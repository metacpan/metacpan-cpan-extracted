use Test;
BEGIN { plan tests => 4 }
use XML::SAX;
use XML::Handler::AxPoint;

# local $XML::SAX::ParserPackage = "XML::SAX::PurePerl";

my $output;

# my $handler = XML::Handler::AxPoint->new(Output => \$output);
my $handler = XML::Handler::AxPoint->new(Output => "foo.pdf");
ok($handler);

my $parser = XML::SAX::ParserFactory->parser(Handler => $handler);
ok($parser);

# ok($parser->isa("XML::SAX::PurePerl"));

chdir("testfiles");

$parser->parse_uri("example.axp");

ok(-e "foo.pdf");

ok(-M _ <= 0);

