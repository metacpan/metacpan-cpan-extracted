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
<p class="tableofcontentline toclevel1"><span class="tocprefix">&#160;&#160;</span><a href="#toc1">Part</a></p>
<p class="tableofcontentline toclevel2"><span class="tocprefix">&#160;&#160;&#160;&#160;</span><a href="#toc2">Chapter</a></p>
<p class="tableofcontentline toclevel3"><span class="tocprefix">&#160;&#160;&#160;&#160;&#160;&#160;</span><a href="#toc3">Section</a></p>
<p class="tableofcontentline toclevel4"><span class="tocprefix">&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;</span><a href="#toc4">Subsection</a></p>
EOF

ok($document->as_html);
foreach my $i (1..4) {
    my $fnstring = qq{>[$i]</a>};
    unlike ($document->toc_as_html, qr/\Q$fnstring\E/, "Footnote skipped $i");
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
            'string' => 'Chapter',
           },
           {
            'level' => '3',
            'index' => 3,
            'string' => 'Section',
           },
           {
            'level' => '4',
            'index' => 4,
            'string' => 'Subsection',
           },
          ];

is_deeply([$document->raw_html_toc], $exp, "Raw toc ok");


