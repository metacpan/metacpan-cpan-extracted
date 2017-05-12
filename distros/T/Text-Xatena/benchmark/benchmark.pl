#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Time::HiRes;
use Benchmark qw(:all :hireswallclock) ;

my $text = <<EOS;
* Xatena

This is Xatena.

- foo
- bar
- baz

+ aaa
+ bbb
+ ccc

>|perl|
test code
||<

^L

Markdown
========

This is markdown

 * foo
 * bar
 * baz

 1. aaa
 2. bbb
 3. ccc


  test code

^L

h1. Textile

A _simple_ demonstration of Textile markup.

* foo
* bar
* baz

# foo
# bar
# baz

<pre><code class="perl">
perl code
</code></pre>

EOS

use Text::Hatena;
use Text::Xatena;
use Text::Markdown;
use Text::Textile;

my $thx      = Text::Xatena->new;
my $markdown = Text::Markdown->new;
my $textile  = Text::Textile->new;

my $results = timethese(-1, {
	"Text::Xatena $Text::Xatena::VERSION" => sub {
		my $html = $thx->format($text);
	},
	"Text::Hatena $Text::Hatena::VERSION" => sub {
		my $html = Text::Hatena->parse($text);
	},
	"Text::Markdown $Text::Markdown::VERSION" => sub {
		my $html = $markdown->markdown($text);
	},
	"Text::Textile $Text::Textile::VERSION" => sub {
		my $html = $textile->process($text);
	},
});

cmpthese($results);

__END__
MacBook Air 1.8GHz Intel Core i7 / 4GB RAM
                          Rate Text::Hatena 0.20 Text::Markdown 1.000031 Text::Textile 2.12 Text::Xatena 0.14
Text::Hatena 0.20       40.0/s                --                    -83%               -85%              -90%
Text::Markdown 1.000031  234/s              486%                      --               -10%              -44%
Text::Textile 2.12       261/s              552%                     11%                 --              -37%
Text::Xatena 0.14        415/s              937%                     77%                59%                --

