use Test::More tests => 3;
use re::engine::TRE;

SKIP: {
    skip "Results in a split loop, rx->offs[0] needs to be {1,1} not {0,0}", 3;
    my @moo = split //, "moo";
    is($moo[0], "m");
    is($moo[1], "o");
    is($moo[2], "o");
}
