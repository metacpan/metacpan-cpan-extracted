use Test::Base;

if ($ENV{WWW_FAVICON_LIVETEST}) {
    plan tests => 1 * blocks;
}
else {
    plan skip_all => '$ENV{WWW_FAVICON_LIVETEST} is not set';
}

use WWW::Favicon qw/detect_favicon_url/;

filters { input => 'detect_favicon_url' };

run_is;

__DATA__

=== google.co.jp
--- input: http://www.google.co.jp/
--- expected: http://www.google.co.jp/favicon.ico

=== id:jkondo
--- input: http://d.hatena.ne.jp/jkondo/
--- expected: http://d.hatena.ne.jp/images/diary/j/jkondo/favicon.ico

