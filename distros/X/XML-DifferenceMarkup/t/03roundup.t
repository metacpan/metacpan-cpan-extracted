use XML::DifferenceMarkup qw(make_diff merge_diff);
use XML::LibXML;

use strict;
use vars qw(*F);

our ($path, @files, $testcount);

sub reform
{
    my $raw = shift;
    if ($raw =~ /<![[]CDATA/) {
	return $raw;
    }

    my $out = '';
    foreach (split /\n/, $raw) {
	$_ =~ s/^\s+//;
	$out .= $_;
	$out .= "\n";
    }

    return $out;
}

BEGIN
{
    $path = "testdata/roundup";
    @files = glob "$path/*.xml";
    $testcount = scalar(@files) / 3;
}

use Test::More tests => 2 * $testcount;

my $parser = XML::LibXML->new(keep_blanks => 0, load_ext_dtd => 0);

my $i = 0;
while ($i < $testcount) {

    my $n = sprintf("%02d", $i);

    my $a = $parser->parse_file("$path/$n" . "a.xml");

    open(F, "$path/$n" . "b.xml");
    my $serb = reform(join '', <F>);
    my $b = $parser->parse_string($serb);

    open(F, "$path/$n" . "d.xml");
    my $serd = reform(join '', <F>);

    my $diff = make_diff($a, $b);
    is(reform($diff->toString(1)), $serd, "diff $n?.xml");

    my $merge = merge_diff($a, $diff);
    is(reform($merge->toString(1)), $serb, "merge $n?.xml");

    ++$i;
}


