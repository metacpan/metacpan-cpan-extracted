use XML::Checker::Parser;

# Uncomment the next line to stop parsing when the first error is encountered.
#local $XML::Checker::FAIL = sub { die };

my $parser = new XML::Checker::Parser (KeepCDATA => 1, NoExpand => 1);
$parser->parsefile (shift);
