#!perl
use strict;
use warnings;
use utf8;
use Data::Dumper;
use Test::More tests => 4;
use Text::Amuse::Functions qw/muse_to_object muse_fast_scan_header muse_format_line/;
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ":encoding(UTF-8)";

BEGIN {
    if (!eval q{ use Test::Differences; unified_diff; 1 }) {
        *eq_or_diff = \&is_deeply;
    }
}

my $muse = <<'MUSE';
#title Test; and test!
#lang fr 

"stop" . semicolon; colon: question? bang! «quote»

"stop" . semicolon ; colon : question ? bang ! « quote »

http://hello.org

semicolon ; 
colon : 
question ?
bang !
« quote »

<verbatim>bang ! bang !</verbatim>

{{{
bang! and bang !
}}}

MUSE

my $html = <<'HTML';

<p>
&quot;stop&quot; . semicolon&#160;; colon&#160;: question&#160;? bang&#160;! «&#160;quote&#160;»
</p>

<p>
&quot;stop&quot; . semicolon&#160;; colon&#160;: question&#160;? bang&#160;! «&#160;quote&#160;»
</p>

<p>
http://hello.org
</p>

<p>
semicolon&#160;;
colon&#160;:
question&#160;?
bang&#160;!
«&#160;quote&#160;»
</p>

<p>
bang ! bang !
</p>

<pre class="example">
bang! and bang !
</pre>
HTML

my $latex = <<'LATEX';

LATEX

{
    my $obj = muse_to_object($muse);
    eq_or_diff $obj->as_html, $html;
    my $header = muse_fast_scan_header($obj->{_private_temp_fh}->filename, 'html');
    is $header->{title}, 'Test&#160;; and test&#160;!';
}

is muse_format_line(html => 'test!'), 'test!';
is muse_format_line(html => 'test!', 'fr'), 'test&#160;!';
