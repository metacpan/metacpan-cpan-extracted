use XML::DifferenceMarkup qw(make_diff);
use XML::LibXML;

use strict;
use vars qw(*D);

our ($path, @files, $testcount);

sub reform
{
    my $out = '';
    foreach (split /\n/, shift) {
	$_ =~ s/^\s+//;
	$out .= $_;
	$out .= "\n";
    }

    return $out;
}

BEGIN
{
    $path = "testdata/diff";
    @files = glob "$path/*.xml";
    $testcount = scalar(@files) / 3;
}

use Test::More tests => $testcount;

my $parser = XML::LibXML->new(keep_blanks => 0, load_ext_dtd => 0);

my $i = 0;
while ($i < $testcount) {

    my $n = sprintf("%02d", $i);

    my $a = $parser->parse_file("$path/$n" . "a.xml");
    my $b = $parser->parse_file("$path/$n" . "b.xml");

    open(D, "$path/$n" . "d.xml");
    my $expected = reform(join '', <D>);

    my $diff = make_diff($a, $b);
    my $actual = reform($diff->toString(1));

    is($actual, $expected, "$path/$n?.xml");

    ++$i;
}


