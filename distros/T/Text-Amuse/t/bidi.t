#!perl

use utf8;
use strict;
use warnings;
use Text::Amuse;
use Text::Amuse::Functions qw/muse_to_object/;
use Text::Amuse::Output;
use Data::Dumper;
BEGIN {
    if (!eval q{ use Test::Differences; unified_diff; 1 }) {
        *eq_or_diff = \&is_deeply;
    }
}
use Test::More tests => 8;

my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";

my $muse =<<'MUSE';
#lang en
#title Bidi

Text <<<و اساسی است باید مجانی باشد>>> 
left to right and again
 <<<و اساسی است باید مجانی باشد>>>

>>>Text goes left to right<<< 
<<<اساسی است باید مجانی>>> 
>>>Text goes left to right<<< 
<<<اساسی است باید مجانی>>>

MUSE

my $esum =<<'MUSE';
#lang fa
#title Idib

>>>Text goes left to right<<<
و اساسی است باید مجانی باشد >>>left to right and again<<<
و اساسی اس<verbatim> >>>
this does nothing
<<<</verbatim>
<<<ت باید مجانی باشد
MUSE

{
    my $obj = muse_to_object($muse);
    my $html = <<'HTML';

<p>
Text <span dir="rtl">و اساسی است باید مجانی باشد</span>&#x200E;
left to right and again
 <span dir="rtl">و اساسی است باید مجانی باشد</span>&#x200E;
</p>

<p>
<span dir="ltr">Text goes left to right</span>&#x200F;
<span dir="rtl">اساسی است باید مجانی</span>&#x200E;
<span dir="ltr">Text goes left to right</span>&#x200F;
<span dir="rtl">اساسی است باید مجانی</span>&#x200E;
</p>
HTML

    my $latex = <<'LTX';

Text \RL{و اساسی است باید مجانی باشد}
left to right and again
 \RL{و اساسی است باید مجانی باشد}


\LR{Text goes left to right}
\RL{اساسی است باید مجانی}
\LR{Text goes left to right}
\RL{اساسی است باید مجانی}

LTX
    eq_or_diff $obj->as_html, $html;
    eq_or_diff $obj->as_latex, $latex;
    ok !$obj->is_rtl;
    ok $obj->is_bidi;
}

{
    my $obj = muse_to_object($esum);
    my $html = <<'HTML';

<p>
<span dir="ltr">Text goes left to right</span>&#x200F;
و اساسی است باید مجانی باشد <span dir="ltr">left to right and again</span>&#x200F;
و اساسی اس &gt;&gt;&gt;
this does nothing
&lt;&lt;&lt;
<span dir="rtl">ت باید مجانی باشد
</span>&#x200E;
</p>
HTML
    my $latex = <<'LTX';

\LR{Text goes left to right}
و اساسی است باید مجانی باشد \LR{left to right and again}
و اساسی اس >>>
this does nothing
<<<
\RL{ت باید مجانی باشد
}

LTX
    eq_or_diff $obj->as_html, $html;
    eq_or_diff $obj->as_latex, $latex;
    ok $obj->is_rtl;
    ok $obj->is_bidi;
}


