use strict;
use warnings;
use t::TestTextTrac;

run_tests;

__DATA__
### h1 test
--- input
= heading 1 =
--- expected
<h1 id="heading1">heading 1</h1>

### h2 test<
--- input
== heading 2 ==
--- expected
<h2 id="heading2">heading 2</h2>

### h3 test
--- input
=== heading 3 ===
--- expected
<h3 id="heading3">heading 3</h3>

### h4 test
--- input
==== heading 4 ====
--- expected
<h4 id="heading4">heading 4</h4>

### h5 test
--- input
===== heading 5 =====
--- expected
<h5 id="heading5">heading 5</h5>

### bold test
--- input
'''bold''' '''bold'''
--- expected
<p>
<strong>bold</strong> <strong>bold</strong>
</p>

### italic test
--- input
''italic'' ''italic''
--- expected
<p>
<i>italic</i> <i>italic</i>
</p>

### bolditalic test
--- input
'''''bolditalic''''' '''''bolditalic'''''
--- expected
<p>
<strong><i>bolditalic</i></strong> <strong><i>bolditalic</i></strong>
</p>

### underline test
--- input
__underline__ __underline__
--- expected
<p>
<span class="underline">underline</span> <span class="underline">underline</span>
</p>

### monospace test
--- input
`monospace` {{{monospace}}}
--- expected
<p>
<tt>monospace</tt> <tt>monospace</tt>
</p>

### strike test
--- input
~~strike~~ ~~strike~~
--- expected
<p>
<del>strike</del> <del>strike</del>
</p>

### sup test
--- input
^sup^ ^sup^
--- expected
<p>
<sup>sup</sup> <sup>sup</sup>
</p>

### sub test
--- input
,,sub,, ,,sub,,
--- expected
<p>
<sub>sub</sub> <sub>sub</sub>
</p>

### br test
--- input
line1[[BR]]line2
--- expected
<p>
line1<br />line2
</p>

### p test
--- input
test
test
--- expected
<p>
test
test
</p>

### ul test
--- input
 * list 1-1
 * list 1-2
   * list 2-1
   * list 2-2
--- expected
<ul><li>list 1-1
</li><li>list 1-2
<ul><li>list 2-1
</li><li>list 2-2</li></ul></li></ul>

### ol test
--- input
 1. list 1-1
 1. list 1-2
   a. list a-1
   a. list a-2
--- expected
<ol><li>list 1-1
</li><li>list 1-2
<ol class="loweralpha"><li>list a-1
</li><li>list a-2</li></ol></li></ol>

### blockquote test
--- input
  This text is a quote from someone else.
--- expected
<blockquote>
<p>
  This text is a quote from someone else.
</p>
</blockquote>

### blockquote2 test
--- input
  Ask not what your country can do for you. Ask what you can do for your country.
  
  --John F. Kennedy
--- expected
<blockquote>
<p>
  Ask not what your country can do for you. Ask what you can do for your country.
</p>
<p>
  --John F. Kennedy
</p>
</blockquote>

### pre test
--- input
{{{
  This is pre-formatted text.
  This also pre-formatted text.
}}}
--- expected
<pre class="wiki">
  This is pre-formatted text.
  This also pre-formatted text.
</pre>

### table test
--- input
||Cell 1||Cell 2||Cell 3||
||Cell 4||Cell 5||Cell 6||
--- expected
<table>
<tr><td>Cell 1</td><td>Cell 2</td><td>Cell 3</td></tr>
<tr><td>Cell 4</td><td>Cell 5</td><td>Cell 6</td></tr>
</table>

### hr test
--- input
line1
----
line2
--- expected
<p>
line1
</p>
<hr />
<p>
line2
</p>

### dl test
--- input
 title1::
  content 1-1
  content 1-2
 title2::
  content 2-1
  content 2-2
  content 2-3
--- expected
<dl>
<dt>title1</dt>
<dd>
content 1-1
content 1-2
</dd>
<dt>title2</dt>
<dd>
content 2-1
content 2-2
content 2-3
</dd>
</dl>

### autolink test
--- input
http://mizzy.org/
[http://mizzy.org/ Title]
--- expected
<p>
<a class="ext-link" href="http://mizzy.org/"><span class="icon"></span>http://mizzy.org/</a>
<a class="ext-link" href="http://mizzy.org/"><span class="icon"></span>Title</a>
</p>

### auto image link test
--- input
http://mizzy.org/test.png
[http://mizzy.org/test.png Image]
--- expected
<p>
<a class="ext-link" href="http://mizzy.org/test.png"><span class="icon"></span>http://mizzy.org/test.png</a>
<a class="ext-link" href="http://mizzy.org/test.png"><span class="icon"></span>Image</a>
</p>

### ul node with single space
--- input
 * indent with
 * single space
   * sublist with
   * two spaces
--- expected
<ul><li>indent with
</li><li>single space
<ul><li>sublist with
</li><li>two spaces</li></ul></li></ul>

### ul node with double space
--- input
  * indent with
  * two spaces
    * sublist with
    * two spaces
--- expected
<ul><li>indent with
</li><li>two spaces
<ul><li>sublist with
</li><li>two spaces</li></ul></li></ul>

### ol node with single space
--- input
 1. indent with
 1. single space
   a. sublist with
   a. two spaces
--- expected
<ol><li>indent with
</li><li>single space
<ol class="loweralpha"><li>sublist with
</li><li>two spaces</li></ol></li></ol>

### ol node with double space
--- input
  1. indent with
  1. two spaces
    a. sublist with
    a. two spaces
--- expected
<ol><li>indent with
</li><li>two spaces
<ol class="loweralpha"><li>sublist with
</li><li>two spaces</li></ol></li></ol>

### dl node with single space
--- input
 title1::
   indent title
   single space
 title2::
   indent content
   double space
--- expected
<dl>
<dt>title1</dt>
<dd>
indent title
single space
</dd>
<dt>title2</dt>
<dd>
indent content
double space
</dd>
</dl>

### dl node with double space
--- input
  title1::
    indent title
    double space
  title2::
    indent content
    double space
--- expected
<dl>
<dt>title1</dt>
<dd>
indent title
double space
</dd>
<dt>title2</dt>
<dd>
indent content
double space
</dd>
</dl>

### unknown short link
--- input
unknown:target
--- expected
<p>
unknown:target
</p>

### unknown long link
--- input
[unknown:target label]
--- expected
<p>
[unknown:target label]
</p>

### escape HTML meta-characters
--- input
foo <bar> baz.
foo '''bar''' baz.

 * foo <bar> bar.
 * foo '''bar''' baz.

 1. foo <bar> bar.
 1. foo '''bar''' baz.

||foo||<bar>||'''baz'''||

{{{
foo <bar> baz.
foo '''bar''' baz.
}}}
--- expected
<p>
foo &lt;bar&gt; baz.
foo <strong>bar</strong> baz.
</p>
<ul><li>foo &lt;bar&gt; bar.
</li><li>foo <strong>bar</strong> baz.</li></ul>
<ol><li>foo &lt;bar&gt; bar.
</li><li>foo <strong>bar</strong> baz.</li></ol>
<table>
<tr><td>foo</td><td>&lt;bar&gt;</td><td><strong>baz</strong></td></tr>
</table>
<pre class="wiki">
foo &lt;bar&gt; baz.
foo '''bar''' baz.
</pre>

### citation link
--- input
>> Someone's original text
>> Someone's original text
>> Someone's original text
> Someone else's reply text
> Someone else's reply text
My reply text

>> Someone's original text
My reply text
--- expected
<blockquote class="citation">
<blockquote class="citation">
<p>
 Someone's original text
 Someone's original text
 Someone's original text
</p>
</blockquote>
<p>
 Someone else's reply text
 Someone else's reply text
</p>
</blockquote>
<p>
My reply text
</p>
<blockquote class="citation">
<blockquote class="citation">
<p>
 Someone's original text
</p>
</blockquote>
</blockquote>
<p>
My reply text
</p>

#### List item
#--- input
#* First
#* Second
#--- expected
#<ul>
#  <li>First</li>
#  <li>Second</li>
#</ul>
#
#### Image
#--- input
#[[Image(cool_diff_box.png)]]
#--- expected
#<img src="cool_diff_box.png" />
