#
# Usage: perl filterInsignifWS.pl insignif_ws.xml
#

use XML::DOM::ValParser;

# Allow whitespace when ELEMENT rule says EMPTY
$XML::Checker::Context::EMPTY::ALLOW_WHITE_SPACE = 1;

my $filename = shift;

# Uncomment the next line to stop parsing when the first error is encountered.
#local $XML::Checker::FAIL = sub { die };

# Uncomment the next line to stop printing error messages
#local $XML::Checker::FAIL = sub { };

# Check while building the XML::DOM
my $parser = new XML::DOM::ValParser (KeepCDATA => 1, NoExpand => 1, 
				      SkipInsignifWS => 1);
my $dom = $parser->parsefile ($filename);

print $dom->toString;
