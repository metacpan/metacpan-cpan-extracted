use Test;
BEGIN { plan tests => 2 }
use XML::SAX;
use XML::Filter::XInclude;
use XML::SAX::Writer;

my $output;

$XML::SAX::ParserPackage = "XML::SAX::PurePerl";

my $parser = XML::SAX::ParserFactory->parser(
    Handler => XML::Filter::XInclude->new(
        Handler => XML::SAX::Writer->new(Output => \$output)
    )
);

$parser->parse_uri("examples/xinclude.xml");

print("output: $output\n");
ok($output);
ok($output =~ /This was included/);

