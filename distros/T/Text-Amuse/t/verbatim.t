#!perl

use utf8;
use strict;
use warnings;
use Test::More tests => 10;

BEGIN {
    if (!eval q{ use Test::Differences; 1 }) {
        *eq_or_diff = \&is_deeply;
    }
}

use Text::Amuse::Functions qw/muse_to_html
                              muse_to_tex
                              muse_to_object
                             /;
use Data::Dumper;

{
    my $muse =<<'MUSE';
{{{
<example>
    This is
      a
      code
      block
</example>
}}}
MUSE
    my $obj = muse_to_object($muse);
    my $latex =<<'LATEX';

\begin{alltt}
<example>
    This is
      a
      code
      block
</example>
\end{alltt}

LATEX
    my $html =<<'HTML';

<pre class="example">
&lt;example&gt;
    This is
      a
      code
      block
&lt;/example&gt;
</pre>
HTML
    eq_or_diff $obj->as_latex, $latex;
    eq_or_diff $obj->as_html, $html;
    # print Dumper($obj);
}
    
{
    my $muse =<<'MUSE';
<example>
{{{
    This is
      a
      code
      block
}}}
</example>
MUSE
    my $obj = muse_to_object($muse);
    my $latex =<<'LATEX';

\begin{alltt}
\{\{\{
    This is
      a
      code
      block
\}\}\}
\end{alltt}

LATEX
    my $html =<<'HTML';

<pre class="example">
{{{
    This is
      a
      code
      block
}}}
</pre>
HTML
    eq_or_diff $obj->as_latex, $latex;
    eq_or_diff $obj->as_html, $html;
    # print Dumper($obj);
}

{
    my $muse =<<'MUSE';
 {{{
    This is
      a
      code
      block
 }}}
MUSE
    my $obj = muse_to_object($muse);
    my $latex =<<'LATEX';

 \{\{\{
This is
a
code
block
 \}\}\}

LATEX
    my $html =<<'HTML';

<p>
 {{{
This is
a
code
block
 }}}
</p>
HTML
    eq_or_diff $obj->as_latex, $latex;
    eq_or_diff $obj->as_html, $html;
    # print Dumper($obj);
}
{
    my $muse =<<'MUSE';
{{{
<example>
    This is
      a
      code
      block
}}}
</example>
MUSE
    my $obj = muse_to_object($muse);
    my $latex =<<'LATEX';

\begin{alltt}
<example>
    This is
      a
      code
      block
\end{alltt}

LATEX
    my $html =<<'HTML';

<pre class="example">
&lt;example&gt;
    This is
      a
      code
      block
</pre>
HTML
    eq_or_diff $obj->as_latex, $latex, "spurious </example> removed";
    eq_or_diff $obj->as_html, $html;
    #print Dumper($obj);
}

{
    my $muse =<<'MUSE';
<example>
{{{
    This is
      a
      code
      block
</example>
}}}
MUSE
    my $obj = muse_to_object($muse);
    my $latex =<<'LATEX';

\begin{alltt}
\{\{\{
    This is
      a
      code
      block
\end{alltt}

LATEX
    my $html =<<'HTML';

<pre class="example">
{{{
    This is
      a
      code
      block
</pre>
HTML
    eq_or_diff $obj->as_latex, $latex, "spurious </example> removed";
    eq_or_diff $obj->as_html, $html;
    # print Dumper($obj);
}
