#!perl

use strict;
use warnings;
use utf8;
use File::Spec::Functions qw/catfile catdir/;
use Text::Amuse;
use Test::More;
use Data::Dumper;

my $dir = catdir(qw/t testfiles/);

opendir (my $dh, $dir) or die "Cannot open $dir $!";
my @files = map { catfile($dir, $_) }
  grep { /\.muse$/ } readdir $dh;
closedir $dh;

plan tests => scalar(@files) * 5;

foreach my $file (@files) {
    # check html as well while we're at this....
    {
        my $doc = Text::Amuse->new(file => $file);
        my @toc = $doc->raw_html_toc;
        my @html = $doc->as_splat_html;
        is (scalar(@toc), scalar(@html), "pieces and toc match");
    }

    my $doc = Text::Amuse->new(file => $file);
    my $full = $doc->as_latex;
    ok ($full, "latex found");
    my @chunks = $doc->as_splat_latex;
    my @empty_chunks = grep { !$_ } @chunks;
    ok (!@empty_chunks, "No empty chunks found");
    if ($doc->wants_toc) {
        ok (@chunks > 1, "Found " . scalar(@chunks) . " chunks for $file")
          or diag "$file wants a toc but has only one chunk";
    }
    else {
        ok (@chunks == 1, "Only one chunk for $file") or diag Dumper(\@chunks);
    }
    is (join('', @chunks), $full, "1:1 between splat and joined latex");
}

