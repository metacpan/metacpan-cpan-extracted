#!/usr/bin/perl 

use Test::More tests => 8;
use XML::Writer::Simple tags => [qw/foo bar/], powertags => [qw/foo_bar table_tr_td/];

is(foo(bar("ugh")), "<foo><bar>ugh</bar></foo>");
is(foo_bar("ugh"), "<foo><bar>ugh</bar></foo>");
is(foo_bar("a","b","c"), "<foo><bar>a</bar><bar>b</bar><bar>c</bar></foo>");
is(foo_bar({attr=>"d"},"a","b","c"), "<foo attr=\"d\"><bar>a</bar><bar>b</bar><bar>c</bar></foo>");

powertag("bar","foo");
is(bar_foo("a","b","c"), "<bar><foo>a</foo><foo>b</foo><foo>c</foo></bar>");

is(table_tr_td( ["a","b","c"],["d","e","f"] ),
   "<table><tr><td>a</td><td>b</td><td>c</td></tr><tr><td>d</td><td>e</td><td>f</td></tr></table>");

powertag(qw/div table tr td/);
is(div_table_tr_td({-style=>'background-color: #defdef;'},
                   [['a','b','c'],
                    ['d','e','f']],
                   [['g','h','i'],
                    ['j','k','l']]),
   '<div style="background-color: #defdef;"><table><tr><td>a</td><td>b</td><td>c</td></tr><tr><td>d</td><td>e</td><td>f</td></tr></table><table><tr><td>g</td><td>h</td><td>i</td></tr><tr><td>j</td><td>k</td><td>l</td></tr></table></div>');

is(div_table_tr_td({-style=>'background-color: #defdef;'},
                   [{-style=>'border: solid 1px #000000;'},
                    ['a','b','c'],
                    ['d','e','f']],
                   [['g','h','i'],
                    ['j','k','l']]),
   '<div style="background-color: #defdef;"><table style="border: solid 1px #000000;"><tr><td>a</td><td>b</td><td>c</td></tr><tr><td>d</td><td>e</td><td>f</td></tr></table><table><tr><td>g</td><td>h</td><td>i</td></tr><tr><td>j</td><td>k</td><td>l</td></tr></table></div>');


