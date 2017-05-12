use Test::More tests => 3;
BEGIN {
    require re::engine::Oniguruma;
    re::engine::Oniguruma->import;
    ok(exists $^H{regcomp}, '$^H{regcomp} exists');
    cmp_ok($^H{regcomp}, '!=', 0);
    re::engine::Oniguruma->unimport;
    ok(!exists $^H{regcomp}, '$^H{regcomp} deleted');
}
