#!perl
use strict;
use warnings;
use utf8;
use Data::Dumper;
use Test::More tests => 5;
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

«quote»?

is this a « quote » ?

http://hello.org

[[http://hello.org]]

semicolon ; 
colon : 
question ?
bang !
« quote »

<verbatim>bang ! bang !</verbatim>

{{{
bang! and bang !
}}}

this: « quote »

this: «quote»

this-is-an-error:«quote» # random output

(««quote»» !)

(«quote»)

(«quote»!)


MUSE

my $html = <<'HTML';

<p>
&quot;stop&quot; . semicolon&#8239;; colon&#160;: question&#8239;? bang&#8239;! «&#160;quote&#160;»
</p>

<p>
&quot;stop&quot; . semicolon&#8239;; colon&#160;: question&#8239;? bang&#8239;! «&#160;quote&#160;»
</p>

<p>
«&#160;quote&#160;»&#8239;?
</p>

<p>
is this a «&#160;quote&#160;»&#8239;?
</p>

<p>
http://hello.org
</p>

<p>
<a class="text-amuse-link text-amuse-is-single-link" href="http://hello.org">http://hello.org</a>
</p>

<p>
semicolon&#8239;;
colon&#160;:
question&#8239;?
bang&#8239;!
«&#160;quote&#160;»
</p>

<p>
bang ! bang !
</p>

<pre class="example">
bang! and bang !
</pre>

<p>
this&#160;: «&#160;quote&#160;»
</p>

<p>
this&#160;: «&#160;quote&#160;»
</p>

<p>
this-is-an-error&#160;:«&#160;quote&#160;» # random output
</p>

<p>
(«&#160;«&#160;quote&#160;»&#160;»&#8239;!)
</p>

<p>
(«&#160;quote&#160;»)
</p>

<p>
(«&#160;quote&#160;»&#8239;!)
</p>
HTML

my $latex = <<'LATEX';

LATEX

{
    my $obj = muse_to_object($muse);
    eq_or_diff $obj->as_html, $html;
    #print $obj->as_html;
    my $header = muse_fast_scan_header($obj->{_private_temp_fh}->filename, 'html');
    is $header->{title}, 'Test&#8239;; and test&#8239;!';
}

is muse_format_line(html => 'test!'), 'test!';
is muse_format_line(html => 'test!', 'fr'), 'test&#8239;!';

is muse_format_line(html => '(««quote»»!)', 'fr'), '(«&#160;«&#160;quote&#160;»&#160;»&#8239;!)';
