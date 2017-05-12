#!perl -w

use strict;
use Test::More;

use Text::Clevery;
use Text::Clevery::Parser;

my $tc = Text::Clevery->new(verbose => 2);

my @set = (
    [<<'T', {   }, <<'X'],
{html_image file="foo.jpg" alt="foobar"}
T
<img src="foo.jpg" alt="foobar" />
X

    [<<'T', { href => 'a.html?foo=bar&baz=qux' }, <<'X'],
{html_image file="foo.jpg" alt="foobar" href=$href}
T
<a href="a.html?foo=bar&amp;baz=qux"><img src="foo.jpg" alt="foobar" /></a>
X

    [<<'T', {  }, <<'X'],
{html_image file="foo.jpg" alt="foobar" width=100 height=200}
T
<img src="foo.jpg" alt="foobar" width="100" height="200" />
X

    [<<'T', {  }, <<'X'],
{html_image file="foo.jpg" alt="foobar" style="border: none"}
T
<img src="foo.jpg" alt="foobar" style="border: none" />
X

    eval { require Image::Size } ? [<<'T', {  }, <<'X', 'auto image size'] : (),
{html_image file="viola.jpg" basedir="t/data"}
T
<img src="viola.jpg" alt="" width="240" height="240" />
X

);

for my $d(@set) {
    my($source, $vars, $expected, $msg) = @{$d};
    is eval { $tc->render_string($source, $vars) }, $expected, $msg
        or do { ($@ && diag $@); diag $source };
}

done_testing;
