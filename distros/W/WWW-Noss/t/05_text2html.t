#!/usr/bin/perl
use 5.016;
use strict;

use Test::More;

use WWW::Noss::TextToHtml qw(text2html escape_html);

my $TEST_TEXT = <<'HERE';
> This is a paragraph.

>< This is another paragraph.

>& This is an additional paragraph.
HERE

my $TEST_ENTITY = '<>< && << >> &&';

my $text2html = text2html($TEST_TEXT);

like(
	$text2html,
	qr/\Q&gt; This is a paragraph.\E/,
	'text2html retained paragraphs'
);
like(
	$text2html,
	qr/\Q&gt;&lt; This is another paragraph.\E/,
	'text2html retained paragraphs'
);
like(
	$text2html,
	qr/\Q&gt;&amp; This is an additional paragraph.\E/,
	'text2html retained paragraphs'
);
like(
	$text2html,
	qr/(<p>.+?<\/p>.*?){3}/s,
	'text2html added paragraph tags'
);

is(
	escape_html($TEST_ENTITY),
	'&lt;&gt;&lt; &amp;&amp; &lt;&lt; &gt;&gt; &amp;&amp;',
	'escape_html performed entity conversions correctly'
);

done_testing;

# vim: expandtab shiftwidth=4
