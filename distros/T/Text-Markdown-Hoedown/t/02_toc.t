use strict;
use Test::More;

use Text::Markdown::Hoedown;

my $src = <<'...';
# 1
## 1.1
### 1.1.1
## 1.2
### 1.2.1
# 2
## 2.2
...

is(markdown_toc($src), <<'...');
<ul>
<li>
<a href="#toc_0">1</a>
<ul>
<li>
<a href="#toc_1">1.1</a>
<ul>
<li>
<a href="#toc_2">1.1.1</a>
</li>
</ul>
</li>
<li>
<a href="#toc_3">1.2</a>
<ul>
<li>
<a href="#toc_4">1.2.1</a>
</li>
</ul>
</li>
</ul>
</li>
<li>
<a href="#toc_5">2</a>
<ul>
<li>
<a href="#toc_6">2.2</a>
</li>
</ul>
</li>
</ul>
...

is(markdown($src, html_options => HOEDOWN_HTML_TOC), <<'...');
<h1 id="toc_0">1</h1>

<h2 id="toc_1">1.1</h2>

<h3 id="toc_2">1.1.1</h3>

<h2 id="toc_3">1.2</h2>

<h3 id="toc_4">1.2.1</h3>

<h1 id="toc_5">2</h1>

<h2 id="toc_6">2.2</h2>
...

done_testing;

