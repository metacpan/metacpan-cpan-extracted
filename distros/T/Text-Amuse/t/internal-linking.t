#!perl

use strict;
use warnings;

use strict;
use warnings;
use utf8;
use Test::More tests => 274;
use Text::Amuse;
use File::Spec::Functions qw/catfile tmpdir/;

my $doc =   Text::Amuse->new(file => catfile(t => testfiles => 'hyper-2.muse'),
                             debug => 0);

my $full_html = $doc->as_html;
my $full_ltx = $doc->as_latex;
my $splat_html = join('', $doc->as_splat_html);
my $splat_ltx =  join('', $doc->as_splat_latex);

for my $split (0..1) {
    my $html = $split ? join('', $doc->as_splat_html) : $doc->as_html;
    my $ltx =  $split ? join('', $doc->as_splat_latex) : $doc->as_latex;
    foreach my $i (2..14) {
        my $str = '\hyperdef{amuse}{valid' . $i . '}{}%';
        my $link = '\hyperref{}{amuse}{valid' . $i . '}{valid' . $i . '}';
        like $ltx, qr{\Q$str\E}, "$str found";
        like $ltx, qr{\Q$link\E}, "$link found";
        unlike $ltx, qr{\#valid\Q$i\E}, "#valid$i not found";
        my $hstr = qq{<a id="text-amuse-label-valid$i" class="text-amuse-internal-anchor"></a>};
        like $html, qr{\Q$hstr\E}, "$hstr found";
        my $hlink = qq{<a class="text-amuse-link" href="#text-amuse-label-valid$i">valid$i</a>};
        like $html, qr{\Q$hlink\E}, "$link found";
    }
    foreach my $i (1..18) {
        my $str = '\hyperdef{amuse}{invalid' . $i . '}{}%';
        my $link = '\hyperref{}{amuse}{invalid' . $i . '}{invalid' . $i . '}';
        unlike $ltx, qr{\Q$str\E}, "$str not found (invalid)";
        like $ltx, qr{\Q$link\E}, "$link found (valid but missing)";
        my $hstr = qq{<a id="text-amuse-label-invalid$i" class="text-amuse-internal-anchor"></a>};
        unlike $html, qr{\Q$hstr\E}, "$hstr not found (invalid)";
        my $hlink = qq{<a class="text-amuse-link" href="#text-amuse-label-invalid$i">invalid$i</a>};
        like $html, qr{\Q$hlink\E}, "$link found (valid but missing)";
    }
}
