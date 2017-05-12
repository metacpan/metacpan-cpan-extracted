use utf8;
use strict;
use warnings;
use lib 't/lib';
use Encode;
use Text::Xatena::Test;
use Cache::MemoryCache;
use LWP::UserAgent;
use LWP::Simple;
local $Text::Xatena::Test::INLINE = "Text::Xatena::Inline::Aggressive";
local $Text::Xatena::Test::INLINE_ARGS = [ cache => Cache::MemoryCache->new ];
{
    no warnings 'redefine';
    *LWP::UserAgent::get = sub {
        my ($self, $uri) = @_;

        my $res = {
            'http://example.com/' => sub {
                HTTP::Response->new(200, "OK", ['Content-Type' => 'text/html'], "<title>Example Web Page</title>");
            },
            'http://example.com/utf-8' => sub {
                HTTP::Response->new(200, "OK", ['Content-Type' => 'text/html'], encode("utf-8", "<title>エグザンプルウェブページ</title>"));
            },
            'http://example.com/shift_jis' => sub {
                HTTP::Response->new(200, "OK", ['Content-Type' => 'text/html'], encode("shift_jis", "<meta charset='shift_jis'><title>エグザンプルウェブページ</title>"));
            },
            'http://example.com/euc-jp' => sub {
                HTTP::Response->new(200, "OK", ['Content-Type' => 'text/html'], encode("euc-jp", "<meta charset='euc-jp'><title>エグザンプルウェブページ</title>"));
            },
            'http://example.com/shift_jis_ct' => sub {
                HTTP::Response->new(200, "OK", ['Content-Type' => 'text/html; charset=shift_jis'], encode("shift_jis", "<title>エグザンプルウェブページ</title>"));
            },
        };

        my $sub = $res->{$uri} or BAIL_OUT("Unexpected web access");
        $sub->();
    };
};


plan tests => 1 * blocks;

run_html;


__END__
=== test
--- input
<a href="http://example.com/">http://example.com/</a>
--- expected
<p>
<a href="http://example.com/">
http://example.com/
</a>
</p>

=== test
--- input
http://example.com/
--- expected
<p>
<a href="http://example.com/">
http://example.com/
</a>
</p>

=== test
--- input
mailto:cho45@lowreal.net
--- expected
<p>
<a href="mailto:cho45@lowreal.net">
cho45@lowreal.net
</a>
</p>

=== test
--- input
[http://example.com/]
--- expected
<p>
<a href="http://example.com/">
http://example.com/
</a>
</p>

=== test
--- input
[http://example.com/:title=Foo bar]
--- expected
<p>
<a href="http://example.com/">
Foo bar
</a>
</p>

=== test
--- input
[http://example.com/:barcode]
--- expected
<p>
<img src="http://chart.apis.google.com/chart?chs=150x150&cht=qr&chl=http%3A%2F%2Fexample.com%2F" title="http://example.com/"/>
</p>

=== test
--- input
[]http://example.com/[]
--- expected
<p>
http://example.com/
</p>

=== test
--- input
<strong>http://example.com/</strong>
--- expected
<p>
<strong>
	<a href="http://example.com/">
	http://example.com/
	</a>
</strong>
</p>

=== test
--- input
<q cite="http://example.com/">http://example.com/</q>
--- expected
<p>
<q cite="http://example.com/">
	<a href="http://example.com/">
	http://example.com/
	</a>
</q>
</p>

=== http title
--- input
[http://example.com/:title]
--- expected
<p>
<a href="http://example.com/">
Example Web Page
</a>
</p>

=== http title
--- input
[http://example.com/utf-8:title]
--- expected
<p>
<a href="http://example.com/utf-8">
エグザンプルウェブページ
</a>
</p>

=== http title
--- input
[http://example.com/shift_jis:title]
--- expected
<p>
<a href="http://example.com/shift_jis">
エグザンプルウェブページ
</a>
</p>

=== http title
--- input
[http://example.com/euc-jp:title]
--- expected
<p>
<a href="http://example.com/euc-jp">
エグザンプルウェブページ
</a>
</p>

=== http title
--- input
[http://example.com/shift_jis_ct:title]
--- expected
<p>
<a href="http://example.com/shift_jis_ct">
エグザンプルウェブページ
</a>
</p>
