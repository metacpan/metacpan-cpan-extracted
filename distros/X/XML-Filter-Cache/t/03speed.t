use Test;
BEGIN {
    warn(
        "\nAbout to benchmark caching. This parses a 70KB file, so be warned\n",
        "that it may take a very long time indeed, depending on which parser gets used\n",
    );
    plan tests => 2;
}
use XML::Filter::Cache;
use XML::SAX::Writer;
use XML::SAX;
use Benchmark;


my $output;
my $writer = XML::SAX::Writer->new(Output => \$output);
my $filter = XML::Filter::Cache->new(
        Handler => $writer, 
        Key => "speed",
        CacheRoot => "./cacheroot",
        );
# local $XML::SAX::ParserPackage = "XML::SAX::PurePerl";
my $parser = XML::SAX::ParserFactory->parser(Handler => $filter);
print "Using a ", ref($parser), " parser object\n";

{
    local $^W;
    eval "sub XML::SAX::Writer::xml_decl {}"
        if ref($parser) eq 'XML::SAX::Expat'; # Dont output this
}

my $time1 = timeit(1, sub { $parser->parse_uri("testfiles/large.xml") } );

print "First parse took: ", timestr($time1), "\n";
ok($output);

my $old = $output;

my $time2 = timeit(1, sub { $filter->playback() } );

print "Second parse took: ", timestr($time2), "\n";
ok($output, $old, "Check that cached is identical output");

# if ($output ne $old) {
#    open(FH, ">/tmp/old"); print FH $old; close FH;
#    open(FH, ">/tmp/new"); print FH $output; close FH;
#}

my $timediff = timediff($time1, $time2);

print "Difference: ", timestr($timediff), "\n";

