use Test;
BEGIN { plan tests => 1 }
use XML::Filter::Cache;
use XML::SAX::Writer;

my $output;
my $writer = XML::SAX::Writer->new(Output => \$output);
my $filter = XML::Filter::Cache->new(
        Handler => $writer, 
        Key => "test",
        CacheRoot => "./cacheroot",
        );
$filter->playback();

print $output, "\n";

ok($output);

