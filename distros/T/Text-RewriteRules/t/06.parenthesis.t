# -*- cperl -*-
use Test::More tests => 9;
use Text::RewriteRules;

RULES first
[[:PB:]]==>+
ENDRULES

RULES second
[[:BB:]]==>*
ENDRULES

RULES third
[[:CBB:]]==>#
ENDRULES

RULES fourth
[[:CBB:]]==>[$+{CBB}]
ENDRULES

RULES fifth
[[:BB:]]==>{$+{BB}}
ENDRULES

RULES sixth
[[:PB:]]==>{$+{PB}}
ENDRULES

my $in = "ola (a (b)(d zbr='foo')(c)) munto (c()()ba)((())) ola";
my $in2 = "ola ((a hmm =\"hmm\")(b)(d zbr='foo'/)(c)) lua ((/c)(/b)(/a) 
    ola (a hmm =\"hmm\")(b)(d zbr='foo'/))(c)(/c)(aaa()(/a) ola";

my $on = "ola [a [b][d zbr='foo'][c]] munto [c[][]ba][[[]]] ola";
my $on2 = "ola [[a hmm =\"hmm\"][b][d zbr='foo'/][c]] lua [[/c][/b][/a] 
    ola [a hmm =\"hmm\"][b][d zbr='foo'/]][c][/c][aaa[][/a] ola";

my $un = "ola {a {b}{d zbr='foo'}{c}} munto {c{}{}ba}{{{}}} ola";
my $un2 = "ola {{a hmm =\"hmm\"}{b}{d zbr='foo'/}{c}} lua {{/c}{/b}{/a} 
    ola {a hmm =\"hmm\"}{b}{d zbr='foo'/}}{c}{/c}{aaa{}{/a} ola";

is(first($in),"ola + munto ++ ola");
is(first($in2),"ola + lua +++(aaa++ ola");

is(second($on),"ola * munto ** ola");
is(second($on2),"ola * lua ***[aaa** ola");

is(third($un),"ola # munto ## ola");
is(third($un2),"ola # lua ###{aaa## ola");

is(fourth("{ xpto } {{"),"[ xpto ] {{");
is(fifth("]] [xpto] {{"),"]] {xpto} {{");
is(sixth("((xpto)(xpto){{"),"({xpto}{xpto}{{");

