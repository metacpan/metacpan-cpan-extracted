#!/usr/bin/perl
use 5.016;
use strict;

use Test::More;

use WWW::Noss::TextToHtml qw(text2html escape_html unescape_html strip_tags);

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

subtest 'unescape_html ok' => sub {
    is(
        unescape_html('&#72;&#69;&#76;&#76;&#79;'),
        'HELLO',
        'numerical entities ok'
    );
    is(
        unescape_html('&#x0048;&#x0045;&#x004c;&#x004c;&#x004f;'),
        'HELLO',
        'hexadecimal entities ok'
    );
    is(
        unescape_html('&Alpha;&Beta;&Gamma;&Delta;&Epsilon;'),
        join('', map { chr } 913 .. 917),
        'named entities ok'
    );
    is(
        unescape_html('&#x0026;amp&#x003b;'),
        '&amp;',
        'expanding into entities ok'
    );
};

subtest 'strip_tags ok' => sub {
    is(
        strip_tags('<p>Some</p><h1>Test</h1><div class="test">Text</div>'),
        'SomeTestText',
        'strip_tags ok'
    );
    is(
        strip_tags('<p <!-- yadda yadda -->>Test</p><h1 <!-- -->>Text</h1>'),
        'TestText',
        'nested tags ok'
    );
    is(
        strip_tags('<p>Test<![CDATA[ < > & >:-) ]]>Text</p>'),
        'TestText',
        'CDATA ok'
    );
    is(
        strip_tags(q{<p attr="\">"><b attr='\'>'>Text</b></p>}),
        'Text',
        '">" in attribute ok'
    );
};

done_testing;

# vim: expandtab shiftwidth=4
