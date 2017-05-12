use strict;
use warnings;
use Data::Dumper;
use Text::Amuse::Document;
use Text::Amuse::Output;
use File::Spec::Functions;
use Test::More;

plan tests => 9;

my $file = catfile(t => testfiles => "splat.muse");
my $doc = Text::Amuse::Document->new(file => $file);
my $output = Text::Amuse::Output->new(document => $doc,
                                      format => 'html');

my $splat = $output->process(split => 1);

my $expected =  [
                 '<h2 id="toc1">Here</h2>


<p>
Here there is the body <a href="#fn1" class="footnote" id="fn_back1">[1]</a>
</p>

<p class="fnline"><a class="footnotebody" href="#fn_back1" id="fn1">[1]</a> First
</p>
',


                 '<h3 id="toc2">chapter</h3>


<p>
Here we go <a href="#fn2" class="footnote" id="fn_back2">[2]</a>
</p>

<p class="fnline"><a class="footnotebody" href="#fn_back2" id="fn2">[2]</a> Second
</p>
',


                 '<h4 id="toc3">section <a href="#fn3" class="footnote" id="fn_back3">[3]</a></h4>


<p>
section <a href="#fn4" class="footnote" id="fn_back4">[4]</a>
</p>

<p>
End of the game
</p>

<p class="fnline"><a class="footnotebody" href="#fn_back3" id="fn3">[3]</a> Third
</p>

<p class="fnline"><a class="footnotebody" href="#fn_back4" id="fn4">[4]</a> Fourth
</p>
',

          '<h5 id="toc4">subsection <a href="#fn5" class="footnote" id="fn_back5">[5]</a></h5>


<p>
subsection
</p>
<h6>subsub section <a href="#fn6" class="footnote" id="fn_back6">[6]</a></h6>


<p class="fnline"><a class="footnotebody" href="#fn_back5" id="fn5">[5]</a> Fifth
</p>

<p class="fnline"><a class="footnotebody" href="#fn_back6" id="fn6">[6]</a> Sixth
</p>
'

                ];


is_deeply($splat, $expected, "Splat html OK");


my $toc = [
           {
            'level' => '1',
            'index' => 1,
            'string' => 'Here'
           },
           {
            'level' => '2',
            'index' => 2,
            'string' => 'chapter'
           },
           {
            'level' => '3',
            'index' => 3,
            'string' => 'section <a href="#fn3" class="footnote" id="fn_back3">[3]</a>'
           },
           {
            'level' => '4',
            'index' => 4,
            'string' => 'subsection <a href="#fn5" class="footnote" id="fn_back5">[5]</a>'
           },
          ];

# print Dumper([$output->table_of_contents]);

is_deeply( [ $output->table_of_contents ], $toc, "ToC ok");

use Text::Amuse;

my $splatdoc = Text::Amuse->new(file => $file);

# print Dumper([$splatdoc->as_splat_html]);

is_deeply( [ $splatdoc->as_splat_html ], $expected, "ok from Text::Amuse");


is_deeply( [ $splatdoc->raw_html_toc ], $toc, "ToC ok");

ok($splatdoc->as_html);
ok($splatdoc->as_latex);
ok($splatdoc->wants_toc);
is_deeply( [ $splatdoc->raw_html_toc ], $toc, "ToC ok");
is_deeply( [ $splatdoc->as_splat_html ], $expected,
           "ok again from Text::Amuse");
