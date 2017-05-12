use Test::More tests => 3;
BEGIN {
    require re::engine::PCRE;
    re::engine::PCRE->import;
    ok(exists $^H{regcomp}, '$^H{regcomp} exists');
    cmp_ok($^H{regcomp}, '!=', 0);
    re::engine::PCRE->unimport;
    ok(!exists $^H{regcomp}, '$^H{regcomp} deleted');
}
