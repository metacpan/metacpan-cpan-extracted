use strict;
use warnings;
use utf8;
use Test::More;
use Text::Amuse::Output::Image;

plan tests => 35;
my ($image, $ltx, $html);

$image = Text::Amuse::Output::Image->new(
                                         width => 25,
                                         wrap => "r",
                                         filename => "test.png",
                                        );

ok($image->wrap, "wrap ok");
is($image->width, "0.25", "width ok");
is($image->width_html, "25%", "html width ok");
is($image->width_latex, "0.25\\textwidth", "LaTeX width ok");

$ltx =<<'EOF';

\begin{wrapfigure}{r}{0.25\textwidth}
\centering
\includegraphics[keepaspectratio=true,height=0.75\textheight,width=0.25\textwidth]{test.png}
\end{wrapfigure}
EOF

is($image->as_latex, $ltx, "TeX output ok");

$html =<<'EOF';

<div class="float_image_r" style="width:25%;">
<img src="test.png" alt="test.png" class="embedimg" />
</div>
EOF

is($image->as_html, $html, "HTML output ok");
is($image->as_latex, $ltx, "TeX output ok (2)");
is($image->as_html, $html, "HTML output ok (2)");



$image = Text::Amuse::Output::Image->new(
                                         filename => "test.png",
                                        );

ok(!$image->wrap, "no wrap ok");
is($image->width, "1", "width ok");
is($image->width_html, "100%", "html width ok");
is($image->width_latex, "\\textwidth", "LaTeX width ok");

$ltx =<<'EOF';

\begin{figure}[htbp!]
\centering
\includegraphics[keepaspectratio=true,height=0.75\textheight,width=\textwidth]{test.png}
\end{figure}
EOF

is($image->as_latex, $ltx, "TeX output ok");

$html =<<'EOF';

<div class="image">
<img src="test.png" alt="test.png" class="embedimg" />
</div>
EOF

is($image->as_html, $html, "HTML output ok");
is($image->as_latex, $ltx, "TeX output ok (2)");
is($image->as_html, $html, "HTML output ok (2)");




$image = Text::Amuse::Output::Image->new(
                                         filename => 'test.png',
                                         width => 75,
                                         wrap  => 'l',
                                        );

ok($image->wrap, "wrap ok");
is($image->width, "0.75", "width ok");
is($image->width_html, "75%", "html width ok");
is($image->width_latex, "0.75\\textwidth", "LaTeX width ok");

$ltx =<<'EOF';

\begin{wrapfigure}{l}{0.75\textwidth}
\centering
\includegraphics[keepaspectratio=true,height=0.75\textheight,width=0.75\textwidth]{test.png}
\end{wrapfigure}
EOF

is($image->as_latex, $ltx, "TeX output ok");

$html =<<'EOF';

<div class="float_image_l" style="width:75%;">
<img src="test.png" alt="test.png" class="embedimg" />
</div>
EOF

is($image->as_html, $html, "HTML output ok");
is($image->as_latex, $ltx, "TeX output ok (2)");
is($image->as_html, $html, "HTML output ok (2)");




$image = Text::Amuse::Output::Image->new(
                                         filename => 'test.png',
                                         width => 50,
                                         wrap  => 'f',
                                        );

ok($image->wrap, "wrap ok");
is($image->width, "0.50", "width ok");
is($image->width_html, "50%", "html width ok");
is($image->width_latex, "0.50\\textwidth", "LaTeX width ok");

$ltx =<<'EOF';

\begin{figure}[htbp!]
\centering
\includegraphics[keepaspectratio=true,height=0.75\textheight,width=0.50\textwidth]{test.png}
\end{figure}
\clearpage
EOF

is($image->as_latex, $ltx, "TeX output ok");

$html =<<'EOF';

<div class="float_image_f" style="width:50%;">
<img src="test.png" alt="test.png" class="embedimg" />
</div>
EOF

is($image->as_html, $html, "HTML output ok");
is($image->as_latex, $ltx, "TeX output ok (2)");
is($image->as_html, $html, "HTML output ok (2)");



eval {
    $image = Text::Amuse::Output::Image->new(
                                             filename => "testù.png",
                                            );
};
ok($@, "Exception raised with illegal filename: $@");
eval {
    $image = Text::Amuse::Output::Image->new(
                                             filename => "test.pdf",
                                            );
};
ok($@, "Exception raised with wrong extension: $@");

eval {
    $image = Text::Amuse::Output::Image->new(
                                             filename => "test.jpeg",
                                             width => "abc",
                                            );
};
ok($@, "Exception raised with wrong width: $@");



