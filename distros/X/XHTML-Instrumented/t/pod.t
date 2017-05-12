use Test::More;

eval 'use Test::Pod 1.00;';
if ($@) {
    plan skip_all => 'Test::Pod 1.00 required for testing POD';
} else {
    plan tests => 1;
}

ok(1, q(use "Build testpodcoverage" for this test));

