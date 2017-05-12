#
#  Look in Path.pm for path usage
#

use XML::Parser;
use XML::Parser::Grove;
use XML::Grove;
use XML::Grove::Path;

die "usage: test-path.pl XML-FILE [PATH ...]\n"
    if ($#ARGV == -1);
my $doc = shift @ARGV;

my $parser = XML::Parser->new(Style => 'grove');
$parser->parsefile ($doc);
my $grove = $parser->{Grove};

my $path;
foreach $path (@ARGV) {
    print "$path = " . $grove->at_path($path) . "\n";
}

if ($doc =~ /REC-xml-19980210/) {
    $path = "/spec/header/title/[0]";
    print "$path = " . $grove->at_path($path) . "\n";
    $path = "/spec/header/pubdate/day/[0]";
    print "$path = " . $grove->at_path($path) . "\n";
    $path = "/spec/header/pubdate/month/[0]";
    print "$path = " . $grove->at_path($path) . "\n";
    $path = "/spec/header/pubdate/year/[0]";
    print "$path = " . $grove->at_path($path) . "\n";
}
