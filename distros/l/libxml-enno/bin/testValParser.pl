use XML::DOM::ValParser;

# Allow whitespace when ELEMENT rule says EMPTY
$XML::Checker::Context::EMPTY::ALLOW_WHITE_SPACE = 1;

my $filename = shift;

# Uncomment the next line to stop parsing when the first error is encountered.
#local $XML::Checker::FAIL = sub { die };

# Check while building the XML::DOM
my $parser = new XML::DOM::ValParser (KeepCDATA => 1, NoExpand => 1, @ARGV);
my $dom = $parser->parsefile ($filename);

#print $dom->toString;
