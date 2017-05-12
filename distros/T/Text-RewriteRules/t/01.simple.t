# -*- cperl -*-
use Test::More tests => 54;
use Text::RewriteRules;

## Replace
RULES first
a==>b
ENDRULES

is(first("bar"),"bbr");

## Replace Ignore Case
RULES ifirst
a=i=>b
ENDRULES

is(ifirst("BAR"),"BbR");


### --- ###


## Replace with references...
RULES second
a(\d+)==>$1
ENDRULES

is(second("a342"),"342");
is(second("b342"),"b342");
is(second("ba2cd"),"b2cd");


## Replace Ignore Case with references...
RULES isecond
a(\d+)=i=>$1
ENDRULES

is(isecond("A342"),"342");
is(isecond("b342"),"b342");
is(isecond("ba2cd"),"b2cd");


### --- ###


## Conditional
RULES third
b(a+)b==>bbb!! length($1)>5
ENDRULES

is(third("bab"), "bab");
is(third("baab"), "baab");
is(third("baaab"), "baaab");
is(third("baaaab"), "baaaab");
is(third("baaaaab"), "baaaaab");
is(third("baaaaaab"), "bbb");
is(third("baaaaaaab"), "bbb");


## Conditional Ignore Case
RULES ithird
b(a+)b=i=>bbb!! length($1)>5
ENDRULES

is(ithird("bAb"), "bAb");
is(ithird("baab"), "baab");
is(ithird("bAaAb"), "bAaAb");
is(ithird("baAaAb"), "baAaAb");
is(ithird("bAaAaAb"), "bAaAaAb");
is(ithird("baAaAaAb"), "bbb");
is(ithird("bAaAaAaAb"), "bbb");


### --- ###


## Eval Conditional
RULES fourth
b(\d+)=e=>'b' x $1 !! $1 > 5
ENDRULES

is(fourth("b1"), "b1");
is(fourth("b2"), "b2");
is(fourth("b5"), "b5");
is(fourth("b6"), "bbbbbb");
is(fourth("b8"), "bbbbbbbb");


## Eval Conditional with Ignore Case
RULES ifourth
b(\d+)=i=e=>'b' x $1 !! $1 > 5
ENDRULES

is(ifourth("b1"), "b1");
is(ifourth("B2"), "B2");
is(ifourth("b5"), "b5");
is(ifourth("B6"), "bbbbbb");
is(ifourth("b8"), "bbbbbbbb");


### --- ###


## Eval
RULES fifth
b(\d+)=e=>'b' x $1
ENDRULES

is(fifth("b1"), "b");
is(fifth("b2"), "bb");
is(fifth("b5"), "bbbbb");
is(fifth("b8"), "bbbbbbbb");


## Eval with ignore case
RULES ififth
(b)(\d+)=i=eval=>$1 x $2
ENDRULES

is(ififth("b1"), "b");
is(ififth("B2"), "BB");
is(ififth("b5"), "bbbbb");
is(ififth("B8"), "BBBBBBBB");


### --- ###


### Don't like this
### the return value should be used, I think.
RULES sixth
=b=> $_="AA${_}AA"
ENDRULES

is(sixth("foo"),"AAfooAA");


### --- ###


## Last...
RULES seventh
bbbbbb=l=>
b==>bb
ENDRULES

is(seventh("b"),"bbbbbb");

## Last... with ignore case
RULES iseventh
bbbbbb=i=l=>
b==>bB
ENDRULES

is(iseventh("b"),"bBBBBB");




### --- ###

# ignore and NOT ignore

RULES eigth
a=i=>c
b==>d
ENDRULES

is(eigth("abc"),"cdc");
is(eigth("Abc"),"cdc");
is(eigth("aBc"),"cBc");

# ignore all

RULES/i ieigth
a==>c
b==>d
ENDRULES


is(ieigth("abc"),"cdc");
is(ieigth("Abc"),"cdc");
is(ieigth("aBc"),"cdc");


# ignore all... =i= does nothing

RULES/i iieigth
a=i=>c
b==>d
ENDRULES


is(iieigth("abc"),"cdc");
is(iieigth("Abc"),"cdc");
is(iieigth("aBc"),"cdc");


# Test last with condition

RULES more
(...)=l=>!!$1 eq "bar"
ar==>oo
ENDRULES

is(more("bar"),"bar");
is(more("arre"),"oore");

