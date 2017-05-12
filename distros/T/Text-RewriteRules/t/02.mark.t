# -*- cperl -*-
use warnings;
use strict;
use Test::More tests => 9;
use Text::RewriteRules;

## Replace
MRULES first
b==>bb
r==>
ENDRULES

is(first("bar"),"bba");



## Replace (ignore case)
RULES/mx ifirst
b=i=>bb

r==>
ENDRULES

is(ifirst("Bar"),"bba");



## Eval
MRULES second
b=eval=>'b' x 2
r==>
ENDRULES

is(second("bar"),"bba");



## Eval with ignore case
MRULES isecond
(b)=i=e=>$1 x 2
r==>
ENDRULES

is(isecond("Bar"),"BBa");


MRULES third
a==>b!!1
ENDRULES

is(third("bab"),"bbb");

## use of flag instead of MRULES
RULES/m fourth
b==>bb
r==>
ENDRULES

is(fourth("bar"),"bba");

## Eval
MRULES fifth
b=eval=>$a = log(2); $a = sin($a);'b' x 2
r==>
ENDRULES

is(fifth("bar"),"bba");

## Simple Last 
MRULES sixth
bar==>ugh
foo=l=>
ENDRULES

is(sixth("barfoobar"),"ughfoobar");

## Last with condition
MRULES seventh
bar==>ugh
f(o+)=l=>!!length($1)>2
ENDRULES

is(seventh("barfoobarfooobar"),"ughfooughfooobar");
