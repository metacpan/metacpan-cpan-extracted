use Test;
BEGIN { plan tests => 5 }
use XML::SAX;
use XML::SAX::PurePerl;
use XML::Filter::XSLT;
use XML::Handler::AxPoint;

# local $XML::SAX::ParserPackage = "XML::SAX::PurePerl";

my $output;

# my $handler = XML::Handler::AxPoint->new(Output => \$output);
my $handler = XML::Handler::AxPoint->new(Output => "foo2.pdf");
ok($handler);

my $filter = XML::Filter::XSLT->new(Handler => $handler);
ok($filter);

my $parser = XML::SAX::PurePerl->new(Handler => $filter);
ok($parser);

# ok($parser->isa("XML::SAX::PurePerl"));

chdir("testfiles");

$filter->set_stylesheet_uri("demo.xsl");
$parser->parse_uri("example.axp");

ok(-e "foo2.pdf");

ok(-M _ <= 0);

