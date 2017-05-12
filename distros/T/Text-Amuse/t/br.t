use strict;
use warnings;
use utf8;
use Test::More tests => 6;
use Text::Amuse::Functions qw/muse_to_html muse_to_tex/;

my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";


my $muse =<<'EOF';
#title test

<em>à
<br>
đ</em>
EOF

my $html =<<'EOF';

<p>
<em>à
<br />
đ</em>
</p>
EOF

my $ltx =<<'EOF';

\emph{à
\forcelinebreak 
đ}

EOF

is muse_to_tex($muse), $ltx, "latex ok";
is muse_to_html($muse), $html, "html ok";


$muse =<<'EOF';
#title test

à<br>đ

à
<br>
đ
EOF

$html =<<'EOF';

<p>
à<br />đ
</p>

<p>
à
<br />
đ
</p>
EOF

$ltx =<<'EOF';

à\forcelinebreak đ


à
\forcelinebreak 
đ

EOF

is muse_to_tex($muse), $ltx, "latex ok (inlined and standalone)";
is muse_to_html($muse), $html, "html ok (inlined and standalone)";


$muse =<<'EOF';
#title test

à<br>đ

 <br> 

à
<br>
đ
EOF

$html =<<'EOF';

<p>
à<br />đ
</p>

<p>
 <br />
</p>

<p>
à
<br />
đ
</p>
EOF

$ltx =<<'EOF';

à\forcelinebreak đ



\bigskip


à
\forcelinebreak 
đ

EOF

is muse_to_tex($muse), $ltx, "latex ok (all 3 cases)";
is muse_to_html($muse), $html, "html ok (all 3 cases)";

