use XML::DOM;
use XML::Checker;
use XML::Checker::DOM;

my $filename = shift;
my $parser = new XML::DOM::Parser (KeepCDATA => 1, NoExpand => 1);
my $dom = $parser->parsefile ($filename);

print $dom->toString;

# Uncomment the next line to stop checking when the first error is encountered.
#local $XML::Checker::FAIL = sub { die };

my $checker = new XML::Checker;
$dom->check ($checker);

