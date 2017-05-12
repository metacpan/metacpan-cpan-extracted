use strict;
use warnings;
use Test::More;
use Text::Amuse;
use File::Spec::Functions qw/catfile tmpdir/;
use Data::Dumper;

plan tests => 9;

my $document =
  Text::Amuse->new(file => catfile(t => testfiles => 'headings-with-fn.muse'));

my $htmltoc =<<'EOF';
<p class="tableofcontentline toclevel1"><span class="tocprefix">&nbsp;&nbsp;</span><a href="#toc1">Part</a></p>
<p class="tableofcontentline toclevel2"><span class="tocprefix">&nbsp;&nbsp;&nbsp;&nbsp;</span><a href="#toc2">Chapter [1]</a></p>
<p class="tableofcontentline toclevel3"><span class="tocprefix">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span><a href="#toc3">Section [2]</a></p>
<p class="tableofcontentline toclevel4"><span class="tocprefix">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span><a href="#toc4">Subsection [3]</a></p>
EOF

ok($document->as_html);
foreach my $i (1..4) {
    my $fnstring = qq{<a href="#fn$i" class="footnote" id="fn_back$i">[$i]</a>};
    like ($document->toc_as_html, qr/\Q\E/, "Found footnote $i");
}
is($document->toc_as_html, $htmltoc, "ToC looks good");
ok($document->as_latex);
ok($document->wants_toc);

print Dumper([$document->raw_html_toc]);

my $exp = [
           {
            'level' => '1',
            'index' => 1,
            'string' => 'Part',
           },
           {
            'level' => '2',
            'index' => 2,
            'string' => 'Chapter <a href="#fn1" class="footnote" id="fn_back1">[1]</a>',
           },
           {
            'level' => '3',
            'index' => 3,
            'string' => 'Section <a href="#fn2" class="footnote" id="fn_back2">[2]</a>',
           },
           {
            'level' => '4',
            'index' => 4,
            'string' => 'Subsection <a href="#fn3" class="footnote" id="fn_back3">[3]</a>',
           },
          ];

is_deeply([$document->raw_html_toc], $exp, "Raw toc ok");


