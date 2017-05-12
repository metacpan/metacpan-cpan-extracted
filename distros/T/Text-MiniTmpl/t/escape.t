use warnings;
use strict;
use Test::More;

plan tests => 2;

use URI::Escape;
use Text::MiniTmpl qw( render );

my ($res, $wait);

$res = render('t/tmpl/escape.txt',
    client  => '',
    query   => '',
    text    => '',
    html    => '',
);
$wait = <<'EOF';
Start.
http://google.com/search?client=&q=
<p></p>
<div></div>


End.
EOF
is $res, $wait;

$res = render('t/tmpl/escape.txt',
    client  => 'my app',
    query   => 'is &= works?',
    text    => 'If "a<>b" then <b>OK</b>',
    html    => 'If "a&lt;&gt;b" then <b>OK</b>',
);
$wait = <<"EOF";
Start.
http://google.com/search?client=${\uri_escape('my app')}&q=${\uri_escape('is &= works?')}
<p>If &quot;a&lt;&gt;b&quot; then &lt;b&gt;OK&lt;/b&gt;</p>
<div>If "a&lt;&gt;b" then <b>OK</b></div>


End.
EOF
is $res, $wait;

