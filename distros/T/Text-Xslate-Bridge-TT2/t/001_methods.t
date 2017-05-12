#!perl -w

use strict;
use Test::More;

use Text::Xslate;
use Text::Xslate::Util qw(p);
use Text::Xslate::Bridge::TT2;

#note(Text::Xslate::Bridge::TT2->dump);

my $tx = Text::Xslate->new(
    module => [ 'Text::Xslate::Bridge::TT2' ],
);

my @set = (
    [<<'T', <<'X' ],
    <: "".length() :>
    <: "foo".length() :>
    <: "foo".replace('o', 'x') :>
    <: "foo".replace('o', 'x', 0) :>
    <: "foo".match('(o+)')[0] :>
    <: "foo".search('o') ? "ok" : "not ok" :>
    <: "foo".search('x') ? "ok" : "not ok" :>
    <: "foo".repeat(3) :>
T
    0
    3
    fxx
    fxo
    oo
    ok
    not ok
    foofoofoo
X

    [<<'T', <<'X' ],
    <: [100, 10, 1, 2, 20, 200].nsort().join(",") :>
    <: [100, 10, 1, 2, 20, 200].sort().join(",") :>
    <: ["foo", "bar", "foo"].unique().join(",") :>
    <: {foo => 1, bar => 2}.list("keys").sort().join(",")  :>
T
    1,2,10,20,100,200
    1,10,100,2,20,200
    foo,bar
    bar,foo
X
);

for my $d(@set) {
    my($in, $out, $msg) = @{$d};

    is eval { $tx->render_string($in) }, $out, $msg
        or diag $in;
    if($@){
        diag $@;
    }
}

done_testing;
