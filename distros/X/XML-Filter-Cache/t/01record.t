use Test;
BEGIN { plan tests => 2 }
use XML::SAX;
use XML::Filter::Cache;
use XML::SAX::Writer;

my $output;
my $writer = XML::SAX::Writer->new(Output => \$output);
my $filter = XML::Filter::Cache->new(
        Handler => $writer, 
        Key => "test",
        CacheRoot => "./cacheroot",
        );
local $XML::SAX::ParserPackage = "XML::SAX::PurePerl";
my $parser = XML::SAX::ParserFactory->parser(Handler => $filter);
$parser->parse_string("<foo/>", Handler => $filter);

print $output, "\n";

ok($output);
ok(-e $filter->{filename});

