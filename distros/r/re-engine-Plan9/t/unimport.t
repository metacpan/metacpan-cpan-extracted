use Test::More tests => 3;
BEGIN {
    require re::engine::Plan9;
    re::engine::Plan9->import;
    ok(exists $^H{regcomp}, '$^H{regcomp} exists');
    cmp_ok($^H{regcomp}, '!=', 0);
    re::engine::Plan9->unimport;
    ok(!exists $^H{regcomp}, '$^H{regcomp} deleted');
}
