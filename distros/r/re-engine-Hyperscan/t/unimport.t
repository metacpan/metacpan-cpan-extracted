use Test::More tests => 3;
BEGIN {
    require re::engine::Hyperscan;
    re::engine::Hyperscan->import;
    ok(exists $^H{regcomp}, '$^H{regcomp} exists');
    cmp_ok($^H{regcomp}, '!=', 0);
    re::engine::Hyperscan->unimport;
    ok(!exists $^H{regcomp}, '$^H{regcomp} deleted');
}
