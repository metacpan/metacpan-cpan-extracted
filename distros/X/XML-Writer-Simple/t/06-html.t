#!/usr/bin/perl 

use Test::More tests => 2;
use XML::Writer::Simple ':html';

is(p("foo"), "<p>foo</p>");

is(table(Tr([td([qw.a b c.]),
             td([qw.d e f.]),
             td([qw.g h i.])]))."\n", <<EOH);
<table><tr><td>a</td><td>b</td><td>c</td></tr><tr><td>d</td><td>e</td><td>f</td></tr><tr><td>g</td><td>h</td><td>i</td></tr></table>
EOH



