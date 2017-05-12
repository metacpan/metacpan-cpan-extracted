use XML::DifferenceMarkup qw(merge_diff);
use XML::LibXML;

use strict;
use vars qw(*B);

our ($path, @files, $testcount);

BEGIN
{
    $path = "testdata/merge";
    @files = glob "$path/*.xml";
    $testcount = scalar(@files) / 3;
}

use Test::More tests => $testcount;

my $parser = XML::LibXML->new(keep_blanks => 0, load_ext_dtd => 0);

my $i = 0;
while ($i < $testcount) {

    my $n = sprintf("%02d", $i);

    my $a = $parser->parse_file("$path/$n" . "a.xml");
    my $d = $parser->parse_file("$path/$n" . "d.xml");

    open(B, "$path/$n" . "b.xml");
    my $expected = join '', <B>;

    my $merged = merge_diff($a, $d);
    my $actual = $merged->toString(1);

    is($actual, $expected, "$path/$n?.xml");

    ++$i;
}


