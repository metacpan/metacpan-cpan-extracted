use strict;
use warnings;
use utf8;
use Test::More;
use Text::Markdown::Hoedown;
use B qw(perlstring);

my $cb = Text::Markdown::Hoedown::Renderer::Callback->new();
ok $cb;
$cb->doc_header(sub {
    join('',
        "<doctype html>\n",
        "<html>\n",
    );
});
$cb->normal_text(sub {
    my ($text) = @_;
    $text;
});
$cb->entity(sub {
    my ($text) = @_;
    $text;
});
$cb->header(sub {
    my ($title, $level) = @_;
    qq{<h$level>$title</h$level>\n};
});
$cb->codespan(sub {
    my ($body) = @_;
    qq{<code>$body</code>\n};
});
$cb->paragraph(sub {
    my ($text) = @_;
    "<p>$text</p>\n";
});
$cb->autolink(sub {
    my ($text) = @_;
    qq{<a href="$text">$text</a>};
});
$cb->linebreak(sub {
    '<br>';
});
$cb->underline(sub {
    my ($text) = @_;
    qq{<u>$text</u>};
});
$cb->raw_html_tag(sub {
    my ($text) = @_;
    $text;
});
$cb->image(sub {
    my ($link, $title, $alt) = @_;
    if (defined $title) {
        qq!<img title="$title" alt="$alt" src="$link">!;
    } else {
        qq!<img alt="$alt" src="$link">!;
    }
});
$cb->link(sub {
    my ($link, $title, $content) = @_;
    if (defined $title) {
        qq!<a title="$title" href="$link">$content</a>!;
    } else {
        qq!<a href="$link">$content</a>!;
    }
});
$cb->footnote_ref(sub {
    my ($num) = @_;
	qq!<sup id="fnref$num"><a href="#fn$num" rel="footnote">$num</a></sup>!
});
$cb->footnote_def(sub {
    my ($text, $num) = @_;
	qq!<a href="#fn$num" rev="footnote">$text</a>!
});
$cb->doc_footer(sub {
    "</body></html>\n";
});

my $md = Text::Markdown::Hoedown::Markdown->new(HOEDOWN_EXT_AUTOLINK|HOEDOWN_EXT_UNDERLINE|HOEDOWN_EXT_FOOTNOTES, 16, $cb);
is $md->render(<<'...'), <<',,,';
# hoge
fuga & hige
http://mixi.jp/
`hoge()`
<b>bold</b>
_under_
![Alt text](/path/to/img.jpg "Optional title")
![Alt text](/path/to/img.jpg)

This is [an example](http://example.com/ "Title") inline link.

I get 10 times more traffic from [Google] [1] than from
[Yahoo] [2] or [MSN] [3].

 [1]: http://google.com/        "Google"
 [2]: http://search.yahoo.com/  "Yahoo Search"
 [3]: http://search.msn.com/    "MSN Search"
...
<doctype html>
<html>
<h1>hoge</h1>
<p>fuga & hige
<a href="http://mixi.jp/">http://mixi.jp/</a>
<code>hoge()</code>

<b>bold</b>
_under_
<img title="Optional title" alt="Alt text" src="/path/to/img.jpg">
<img alt="Alt text" src="/path/to/img.jpg"></p>
<p>This is <a title="Title" href="http://example.com/">an example</a> inline link.</p>
<p>I get 10 times more traffic from <a title="Google" href="http://google.com/">Google</a> than from
<a title="Yahoo Search" href="http://search.yahoo.com/">Yahoo</a> or <a title="MSN Search" href="http://search.msn.com/">MSN</a>.</p>
</body></html>
,,,

done_testing;

