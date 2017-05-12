use XML::DifferenceMarkup qw(make_diff);
use XML::LibXML;

use strict;

our ($path, @files, $testcount);

BEGIN
{
    $path = "testdata/faildiff";
    @files = glob "$path/*.xml";
    $testcount = scalar(@files) / 2;
}

use Test::More tests => 1 + $testcount;

eval {
    make_diff;
};
like($@,
     qr/undefined value/,
     "missing arguments");

my $parser = XML::LibXML->new(keep_blanks => 0, load_ext_dtd => 0);

my $i = 0;
while ($i < $testcount) {

    my $n = sprintf("%02d", $i);

    my $a = $parser->parse_file("$path/$n" . "a.xml");
    my $b = $parser->parse_file("$path/$n" . "b.xml");

    eval {
	make_diff($a, $b);
    };
    like($@,
	 qr/^XML::DifferenceMarkup diff: /,
	 "$path/$n?.xml");

    ++$i;
}


