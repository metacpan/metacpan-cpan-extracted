use strict;
use warnings;
use utf8;
use File::Basename 'dirname';
use File::Spec::Functions qw{catdir splitdir rel2abs canonpath};
use lib catdir(dirname(__FILE__), '../lib');
use lib catdir(dirname(__FILE__), 'lib');
use Test::More;
use WWW::Flatten;

use Test::More tests => 2;

my $flattener = WWW::Flatten->new;
my $in;

$in = Mojo::DOM->new(<<'EOF');
<html>
<head>
    <meta content="5;URL=http://example.com/no-a-redirection">
    <meta http-equiv="Refresh" content="5;URL=http://example.com/redirected">
    <meta http-equiv="refresh" content="5;URL=http://example.com/redirected2">
    <link rel="stylesheet" type="text/css" href="css1.css" />
    <link rel="stylesheet" type="text/css" href="css2.css" />
    <script type="text/javascript" src="js1.js"></script>
    <script type="text/javascript" src="js2.js"></script>
    <style>
        a {
            background-image:url(http://example.com/bgimg.png);
        }
    </style>
</head>
<body>
<a href="index1.html">A</a>
<a href="index2.html">B</a>
<a href="mailto:a\@example.com">C</a>
<a href="tel:0000">D</a>
<map name="m_map" id="m_map">
    <area href="index3.html" coords="" title="E" ping="http://example.com/" />
</map>
<script>
    var a = "<a href='hoge'>F</a>";
</script>
<a href="escaped?foo=bar&amp;baz=yada">G</a>
<a href="//example.com">ommit scheme</a>
<a href="http://doublehit.com/" style="background-image:url(http://example.com/bgimg2.png);"></a>
</body>
</html>
EOF

$flattener->filenames({
    'http://example.com/redirected'     => '001',
    'http://example1.com/css1.css'      => '002',
    'http://example1.com/css2.css'      => '003',
    'http://example1.com/js1.js'        => '004',
    'http://example1.com/js2.js'        => '005',
    'http://example1.com/index1.html'   => '006',
    'http://example1.com/index2.html'   => '007',
    'http://example1.com/index3.html'   => '008',
    'http://example.com/'               => '009',
    'http://example1.com/hoge'          => '010',
    'http://example.com'                => '011',
    'http://doublehit.com/'             => '012',
    'http://example.com/bgimg2.png'     => '013',
    'http://example.com/bgimg.png'      => '014',
    'http://example.com/redirected2'    => '015',
});

is $flattener->flatten_html($in, 'http://example1.com/', 'foo/index'), <<'EOF', 'right content';
<html>
<head>
    <meta content="5;URL=http://example.com/no-a-redirection">
    <meta content="5;URL=../001" http-equiv="Refresh">
    <meta content="5;URL=../015" http-equiv="refresh">
    <link href="../002" rel="stylesheet" type="text/css">
    <link href="../003" rel="stylesheet" type="text/css">
    <script src="../004" type="text/javascript"></script>
    <script src="../005" type="text/javascript"></script>
    <style>
        a {
            background-image:url(../014);
        }
    </style>
</head>
<body>
<a href="../006">A</a>
<a href="../007">B</a>
<a href="mailto:a%5C@example.com">C</a>
<a href="tel:0000">D</a>
<map id="m_map" name="m_map">
    <area coords="" href="../008" ping="../009" title="E">
</map>
<script>
    var a = "<a href='hoge'>F</a>";
</script>
<a href="http://example1.com/escaped?foo=bar&amp;baz=yada">G</a>
<a href="../011">ommit scheme</a>
<a href="../012" style="background-image:url(../013);"></a>
</body>
</html>
EOF

$in = <<EOF;
body { background-image:url('/image/a.png'); }
div { background-image:url('/image/b.png'); }
div { background: #fff url('/image/c.png'); }
div { background: #fff url(/image/d.png); }
div { background: #fff url("/image/e.png"); }
div { background: #fff url(/image/?spring15'); }
div { background: #fff URL(/image/f); }
EOF

$flattener->filenames({
    'http://example.com/image/a.png'        => '001',
    'http://example.com/image/b.png'        => '002',
    'http://example.com/image/c.png'        => '003',
    'http://example.com/image/d.png'        => '004',
    'http://example.com/image/e.png'        => '005',
    q{http://example.com/image/?spring15'}  => '006',
    'http://example.com/image/f'            => '007',
});

is $flattener->flatten_css($in, 'http://example.com/', 'foo/index'), <<'EOF', 'right content';
body { background-image:url(../001); }
div { background-image:url(../002); }
div { background: #fff url(../003); }
div { background: #fff url(../004); }
div { background: #fff url(../005); }
div { background: #fff url(../006); }
div { background: #fff url(../007); }
EOF
