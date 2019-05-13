use strict;
use warnings;
use utf8;
use Test::More tests => 8;
use Text::Amuse::Functions qw/muse_to_html muse_to_tex/;

my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";

BEGIN {
    if (!eval q{ use Test::Differences; 1 }) {
        *eq_or_diff = \&is_deeply;
    }
}


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

eq_or_diff muse_to_tex($muse), $ltx, "latex ok";
eq_or_diff muse_to_html($muse), $html, "html ok";


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

eq_or_diff muse_to_tex($muse), $ltx, "latex ok (inlined and standalone)";
eq_or_diff muse_to_html($muse), $html, "html ok (inlined and standalone)";


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

eq_or_diff muse_to_tex($muse), $ltx, "latex ok (all 3 cases)";
eq_or_diff muse_to_html($muse), $html, "html ok (all 3 cases)";

$muse = <<'EOF';
Test

<br>Hello

Here is
<br> this
EOF

$ltx =<<'EOF';

Test


\noindent Hello


Here is
\forcelinebreak  this

EOF

$html = <<'EOF';

<p>
Test
</p>

<p>
<br />Hello
</p>

<p>
Here is
<br /> this
</p>
EOF

eq_or_diff muse_to_tex($muse), $ltx, "latex ok";
eq_or_diff muse_to_html($muse), $html, "html ok";

