use Test::More tests => 3;
BEGIN {
    require re::engine::Lua;
    re::engine::Lua->import;
    ok(exists $^H{regcomp}, '$^H{regcomp} exists');
    cmp_ok($^H{regcomp}, '!=', 0);
    re::engine::Lua->unimport;
    ok(!exists $^H{regcomp}, '$^H{regcomp} deleted');
}
