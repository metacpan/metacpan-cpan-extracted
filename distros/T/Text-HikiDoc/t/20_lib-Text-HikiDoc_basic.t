# $Id: 20_lib-Text-HikiDoc_basic.t,v 1.1 2006/10/12 09:17:20 6-o Exp $
use Test::Base;
use Text::HikiDoc;

plan tests => 1 * blocks;
filters { outline => 'chomp'};

my $obj = Text::HikiDoc->new();
run {
    my $block = shift;
    is $obj->to_html($block->input), $block->output, $block->outline;
}

__END__

===
## test plugin
--- input
{{hoge}}
--- output
<div class="plugin">{{hoge}}</div>
--- outline
plugin - {{hoge}}

===
--- input
a{{hoge}}b
--- output
<p>a<span class="plugin">{{hoge}}</span>b</p>
--- outline
plugin - a{{hoge}}b

===
--- input
a{{hoge
--- output
<p>a{{hoge</p>
--- outline
plugin - a{{hoge

===
--- input
hoge}}b
--- output
<p>hoge}}b</p>
--- outline
plugin - hoge}}b

===
--- input
{{hoge}}
a
--- output
<p><span class="plugin">{{hoge}}</span>
a</p>
--- outline
plugin - {{hoge}}\na

===
--- input
{{hoge}}

a
--- output
<div class="plugin">{{hoge}}</div>
<p>a</p>
--- outline
plugin - {{hoge}}\n\na

===
## test plugin with quotes
--- input
{{hoge("}}")}}
--- output
<div class="plugin">{{hoge("}}")}}</div>
--- outline
plugin with quotes - {{hoge("}}")}}

===
--- input
{{hoge('}}')}}
--- output
<div class="plugin">{{hoge('}}')}}</div>
--- outline
plugin with quotes - {{hoge('}}')}}

===
--- input
{{hoge('
}}
')}}
--- output
<div class="plugin">{{hoge('
}}
')}}</div>
--- outline
plugin with quotes - {{hoge('\n}}\n')}}

===
## test plugin with meta char
--- input
{{hoge("a\"b")}}
--- output
<div class="plugin">{{hoge("a\"b")}}</div>
--- outline
plugin with meta char - {{hoge("a\"b")}}'

===
## test blockquote
--- input
""hoge
--- output
<blockquote>
<p>hoge</p>
</blockquote>
--- outline
blockquote - ""hoge

===
--- input
""hoge
""fuga
--- output
<blockquote>
<p>hoge
fuga</p>
</blockquote>
--- outline
blockquote - ""hoge\n""fuga

===
--- input
""hoge
"" ""fuga
--- output
<blockquote>
<p>hoge</p>
<blockquote>
<p>fuga</p>
</blockquote>
</blockquote>
--- outline
blockquote - ""hoge\n"" ""fuga

===
--- input
"" ! hoge
--- output
<blockquote>
<h1>hoge</h1>
</blockquote>
--- outline
blockquote - "" ! hoge

===
--- input
""foo
""bar
""
""foo
--- output
<blockquote>
<p>foo
bar</p>
<p>foo</p>
</blockquote>
--- outline
blockquote - ""foo\n""bar\n""\n""foo

===
--- input
""foo
""bar
""!foo
--- output
<blockquote>
<p>foo
bar</p>
<h1>foo</h1>
</blockquote>
--- outline
blockquote - ""foo\n""bar\n""!foo

===
--- input
""foo
"" bar
""  baz
--- output
<blockquote>
<p>foo
bar</p>
<pre>
baz
</pre>
</blockquote>
--- outline
blockquote - ""foo\n"" bar\n""  baz

===
--- input
""foo
""	bar
""		baz
--- output
<blockquote>
<p>foo
bar</p>
<pre>
baz
</pre>
</blockquote>
--- outline
blockquote - ""foo\n""\tbar\n""\t\tbaz

===
## test header
--- input
!hoge
--- output
<h1>hoge</h1>
--- outline
header - !hoge

===
--- input
!!hoge
--- output
<h2>hoge</h2>
--- outline
header - !!hoge

===
--- input
!!!hoge
--- output
<h3>hoge</h3>
--- outline
header - !!!hoge

===
--- input
!!!!hoge
--- output
<h4>hoge</h4>
--- outline
header - !!!!hoge

===
--- input
!!!!!hoge
--- output
<h5>hoge</h5>
--- outline
header - !!!!!hoge

===
--- input
!!!!!!hoge
--- output
<h6>hoge</h6>
--- outline
header - !!!!!!hoge

===
--- input
!!!!!!!hoge
--- output
<h6>!hoge</h6>
--- outline
header - !!!!!!!hoge

===
--- input
!foo
!!bar
--- output
<h1>foo</h1>
<h2>bar</h2>
--- outline
header - !foo\n!!bar

===
## test list
--- input
* foo
--- output
<ul>
<li>foo</li>
</ul>
--- outline
list - * foo

===
--- input
* foo
* bar
--- output
<ul>
<li>foo</li>
<li>bar</li>
</ul>
--- outline
list - * foo\n* bar

===
--- input
* foo
** bar
--- output
<ul>
<li>foo<ul>
<li>bar</li>
</ul></li>
</ul>
--- outline
list - * foo\n** bar

===
--- input
* foo
** foo
* bar
--- output
<ul>
<li>foo<ul>
<li>foo</li>
</ul></li>
<li>bar</li>
</ul>
--- outline
list - * foo\n** foo\n* bar

===
--- input
* foo
## foo
* bar
--- output
<ul>
<li>foo<ol>
<li>foo</li>
</ol></li>
<li>bar</li>
</ul>
--- outline
list - * foo\n## foo\n* bar

===
--- input
* foo
# bar
--- output
<ul>
<li>foo</li>
</ul>
<ol>
<li>bar</li>
</ol>
--- outline
list - * foo\n# bar

===
## test list skip
--- input
* foo
*** foo
* bar
--- output
<ul>
<li>foo<ul>
<li><ul>
<li>foo</li>
</ul></li>
</ul></li>
<li>bar</li>
</ul>
--- outline
list skip - * foo\n*** foo\n* bar

===
--- input
# foo
### bar
###baz
--- output
<ol>
<li>foo<ol>
<li><ol>
<li>bar</li>
<li>baz</li>
</ol></li>
</ol></li>
</ol>
--- outline
list skip - # foo\n### bar\n###baz

===
## test hrules
--- input
----
--- output
<hr />
--- outline
hrules - ----

===
--- input
----a
--- output
<p>----a</p>
--- outline
hrules - ----a

===
## test pre
--- input
 foo
--- output
<pre>
foo
</pre>
--- outline
pre -  foo

===
--- input
 \:
--- output
<pre>
\:
</pre>
--- outline
pre -  \:
===
--- input
	foo
--- output
<pre>
foo
</pre>
--- outline
pre - \tfoo

===
## test multi pre
--- input
<<<
foo
>>>
--- output
<pre>
foo
</pre>
--- outline
multi pre - <<<\nfoo\n>>>

===
--- input
<<<
foo
 bar
>>>
--- output
<pre>
foo
 bar
</pre>
--- outline
multi pre - <<<\nfoo\n bar\n>>>

===
--- input
<<<
foo
>>>
<<<
bar
>>>
--- output
<pre>
foo
</pre>
<pre>
bar
</pre>
--- outline
multi pre - <<<\nfoo\n>>>\n<<<\nbar\n>>>

===
--- input
<<< ruby
class A
 def foo(bar)
 end
>>>
--- output
<pre>
class A
 def foo(bar)
 end
</pre>
--- outline
multi pre - with Syntax

===
## test comment
--- input
// foo
--- output unchomp

--- outline
comment - // foo

===
--- input
// foo
--- output unchomp

--- outline
comment - // foo

===
## test paragraph
--- input
foo
--- output
<p>foo</p>
--- outline
paragraph - foo

===
## test escape
--- input
\"\"foo
--- output
<p>""foo</p>
--- outline
escape - \"\"foo

===
## test link
--- input
http://haro.jp/
--- output
<p><a href="http://haro.jp/">http://haro.jp/</a></p>
--- outline
link - http://haro.jp/

===
--- input
[[http://haro.jp/]]
--- output
<p><a href="http://haro.jp/">http://haro.jp/</a></p>
--- outline
link - [[http://haro.jp/]]

===
--- input
[[HikiDoc|http://haro.jp/]]
--- output
<p><a href="http://haro.jp/">HikiDoc</a></p>
--- outline
link - [[HikiDoc|http://haro.jp/]]

===
--- input
[[Hiki|http:/hikiwiki.html]]
--- output
<p><a href="/hikiwiki.html">Hiki</a></p>
--- outline
link - [[Hiki|http:/hikiwiki.html]]

===
--- input
[[Hiki|http:hikiwiki.html]]
--- output
<p><a href="hikiwiki.html">Hiki</a></p>
--- outline
link - [[Hiki|http:hikiwiki.html]]

===
--- input
[[img|http://haro.jp/img.png]]
--- output
<p><a href="http://haro.jp/img.png">img</a></p>
--- outline
link - [[img|http://haro.jp/img.png]]

===
--- input
[[http://haro.jp/img.png]]
--- output
<p><a href="http://haro.jp/img.png">http://haro.jp/img.png</a></p>
--- outline
link - [[http://haro.jp/img.png]]

===
--- input
http://haro.jp/img.png
--- output
<p><img src="http://haro.jp/img.png" alt="img.png" /></p>
--- outline
link - http://haro.jp/img.png

===
--- input
http:/img.png
--- output
<p><img src="/img.png" alt="img.png" /></p>
--- outline
link - http:/img.png

===
--- input
http:img.png
--- outline
<p><img src="img.png" alt="img.png" /></p>
link - http:img.png
--- input
[[Tuna|%CB%EE]]
--- output
<p><a href="%CB%EE">Tuna</a></p>
--- outline
link - [[Tuna|%CB%EE]]

===
--- input
[[""]]
--- output
<p><a href="&quot;&quot;">""</a></p>
--- outline
link - [[""]]

===
--- input
[[%22]]
--- output
<p><a href="%22">%22</a></p>
--- outline
link - [[%22]]

===
--- input
[[&]]
--- output
<p><a href="&amp;">&amp;</a></p>
--- outline
link - [[&]]

===
--- input
[[http://haro.jp/]] and [[HikiDoc|http://haro.jp/]]
--- output
<p><a href="http://haro.jp/">http://haro.jp/</a> and <a href="http://haro.jp/">HikiDoc</a></p>
--- outline
link - [[http://haro.jp/]] and [[HikiDoc|http://haro.jp/]]

===
## test difinition
--- input
:a:b
--- output
<dl>
<dt>a</dt><dd>b</dd>
</dl>
--- outline
difinition - :a:b

===
--- input
:a:b
::c
--- output
<dl>
<dt>a</dt><dd>b</dd>
<dd>c</dd>
</dl>
--- outline
difinition - :a:b\n::c

===
--- input
:a\:b:c
--- output
<dl>
<dt>a:b</dt><dd>c</dd>
</dl>
--- outline
difinition - :a\:b:c

===
--- input
:a:b:c
--- output
<dl>
<dt>a</dt><dd>b:c</dd>
</dl>
--- outline
difinition - :a:b:c

===
## test definition title only
--- input
:a:
--- output
<dl>
<dt>a</dt>
</dl>
--- outline
definition title only - :a:

===
## test definition description only
--- input
::b
--- output
<dl>
<dd>b</dd>
</dl>
--- outline
definition description only- ::b

===
## test definition with link
--- input
:[[Hiki|http://hikiwiki.org/]]:Website
--- output
<dl>
<dt><a href="http://hikiwiki.org/">Hiki</a></dt><dd>Website</dd>
</dl>
--- outline
definition with link - :[[Hiki|http://hikiwiki.org/]]:Website

===
## test definition with modifier
--- input
:'''foo''':bar
--- output
<dl>
<dt><strong>foo</strong></dt><dd>bar</dd>
</dl>
--- outline
definition with modifier - :'''foo''':bar

===
## test table
--- input
||a||b
--- output
<table border="1">
<tr><td>a</td><td>b</td></tr>
</table>
--- outline
table - ||a||b

===
--- input
||a||b||
--- output
<table border="1">
<tr><td>a</td><td>b</td></tr>
</table>
--- outline
table - ||a||b||

===
--- input
||a||b|| 
--- output
<table border="1">
<tr><td>a</td><td>b</td><td> </td></tr>
</table>
--- outline
table - ||a||b|| 

===
--- input
||!a||b||
--- output
<table border="1">
<tr><th>a</th><td>b</td></tr>
</table>
--- outline
table - ||!a||b||

===
--- input
||>1||^2
||^3||4
||>5
--- output
<table border="1">
<tr><td colspan="2">1</td><td rowspan="2">2</td></tr>
<tr><td rowspan="2">3</td><td>4</td></tr>
<tr><td colspan="2">5</td></tr>
</table>
--- outline
table - ||>1||^2\n||^3||4\n||>5

===
--- input
||a||b||c||
||||||||
||d||e||f||
--- output
<table border="1">
<tr><td>a</td><td>b</td><td>c</td></tr>
<tr><td></td><td></td><td></td></tr>
<tr><td>d</td><td>e</td><td>f</td></tr>
</table>
--- outline
table - ||a||b||c||\n||||||||\n||d||e||f||

===
## test table with modifier
--- input
||'''||'''||bar
--- output
<table border="1">
<tr><td><strong>||</strong></td><td>bar</td></tr>
</table>
--- outline
table with modifier - ||'''||'''||bar


===
## test modifier
--- input
'''foo'''
--- output
<p><strong>foo</strong></p>
--- outline
modifier - '''foo'''

===
--- input
''foo''
--- output
<p><em>foo</em></p>
--- outline
modifier - ''foo''

===
--- input
==foo==
--- output
<p><del>foo</del></p>
--- outline
modifier - ==foo==

===
--- input
''foo==bar''baz==
--- output
<p><em>foo==bar</em>baz==</p>
--- outline
modifier - ''foo==bar''baz==

===
--- input
'''foo''' and '''bar'''
--- output
<p><strong>foo</strong> and <strong>bar</strong></p>
--- outline
modifier - '''foo''' and '''bar'''

===
--- input
''foo'' and ''bar''
--- output
<p><em>foo</em> and <em>bar</em></p>
--- outline
modifier - ''foo'' and ''bar''

===
## test nested modifier
--- input
==''foo''==
--- output
<p><del><em>foo</em></del></p>
--- outline
modifier ==''foo''==

===
--- input
''==foo==''
--- output
<p><em><del>foo</del></em></p>
--- outline
modifier ''==foo==''

===
--- input
=='''foo'''==
--- output
<p><del><strong>foo</strong></del></p>
--- outline
modifier =='''foo'''==

===
--- input
'''==foo=='''
--- output
<p><strong><del>foo</del></strong></p>
--- outline
modifier '''==foo=='''

===
--- input
'''''foo'''''
--- output
<p>''<strong>foo</strong>''</p>
--- outline
modifier '''''foo'''''

===
## test modifier and link
--- input
[['''Hiki'''|http://hikiwiki.org/]]
--- output
<p><a href="http://hikiwiki.org/"><strong>Hiki</strong></a></p>
--- outline
modifier and link - [['''Hiki'''|http://hikiwiki.org/]]

===
## test pre and plugin
--- input
 {{hoge}}
--- output
<pre>
{{hoge}}
</pre>
--- outline
pre and plugin -  {{hoge}}

===
--- input
<<<
{{hoge}}
>>>
--- output
<pre>
{{hoge}}
</pre>
--- outline
pre and plugin - <<<\n{{hoge}}\n>>>

===
--- input
{{foo
 1}}
--- output
<div class="plugin">{{foo
 1}}</div>
--- outline
pre and plugin - {{foo\n 1}}

===
# test plugin in modifier
--- input
'''{{foo}}'''
--- output
<p><strong><span class="plugin">{{foo}}</span></strong></p>
--- outline
plugin in modifier - '''{{foo}}'''
