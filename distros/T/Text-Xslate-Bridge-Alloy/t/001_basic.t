#!perl -w

use strict;
use Test::More;

use Text::Xslate;
use Text::Xslate::Bridge::Alloy;

#note(Text::Xslate::Bridge::Alloy->dump);

my $tx = Text::Xslate->new(
    function => { Text::Xslate::Bridge::Alloy->methods },
);

is $tx->render_string('<: "foo".length() :>'), 3;
is $tx->render_string('<: ["foo", "bar", "foo"].unique().join(",") :>'),
    "foo,bar";
is $tx->render_string('<: +{foo => 1, bar => 2}.list("keys").sort().join(",") :>'),
    "bar,foo";

is $tx->render_string(q{<: "foo".replace('o', 'x', 1) :>}),          "fxx";
is $tx->render_string(q{<: "foo".match('(o+)')[0] :>}),              "oo";
is $tx->render_string(q{<: "foo".search('o') ? "ok" : "not ok" :>}), "ok";
is $tx->render_string(q{<: "foo".search('x') ? "ok" : "not ok" :>}), "not ok";

done_testing;
