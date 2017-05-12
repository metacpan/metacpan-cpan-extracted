# -*- cperl -*-
use Test::More tests => 4;
use Text::RewriteRules;

RULES/x first
a b c ==>cba
ENDRULES

is(first("abc"),"cba");
is(first("a b c"), "a b c");


RULES/x second
a
b
c
==>cba
ENDRULES

is(second("abc"),"cba");
is(second("a b c"), "a b c");
