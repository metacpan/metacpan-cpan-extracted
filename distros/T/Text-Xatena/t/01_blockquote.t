use strict;
use warnings;
use lib 't/lib';
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
        local $_ = $uri;
        if (qr|http://example.com/|) {
            HTTP::Response->new(200, "OK", [], "<title>Example Web Page</title>");
        } else {
            die "unknown url";
        }
    };
};

plan tests => 1 * blocks;

run_html;


__END__

=== test
--- input
>>
quote
<<
--- expected
<blockquote>
<p>quote</p>
</blockquote>

=== test
--- input
>>
quote1
>>
quote2
<<
<<
--- expected
<blockquote>
    <p>quote1</p>
    <blockquote>
        <p>quote2</p>
    </blockquote>
</blockquote>

=== test
--- input
>http://example.com/>
quote
<<
--- expected
<blockquote cite="http://example.com/">
	<p>quote</p>
	<cite><a href="http://example.com/">http://example.com/</a></cite>
</blockquote>

=== http
--- input
>http://example.com/:title>
quote
<<
--- expected
<blockquote cite="http://example.com/">
	<p>quote</p>
	<cite><a href="http://example.com/">Example Web Page</a></cite>
</blockquote>

=== cite
--- input
>foobar>
quote
<<
--- expected
<blockquote>
	<p>quote</p>
	<cite>foobar</cite>
</blockquote>


=== test
--- input
>>
quote
<<
test
--- expected
<blockquote>
<p>quote</p>
</blockquote>
<p>test</p>

=== bug1
--- input
>>
* hoge1
hoge2
<<
hoge3
--- expected
<blockquote>
	<div class="section">
		<h3>hoge1</h3>
		<p>hoge2</p>
	</div>
</blockquote>
<p>hoge3</p>
