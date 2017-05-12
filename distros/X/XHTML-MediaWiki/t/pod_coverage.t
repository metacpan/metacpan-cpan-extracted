use Test::More;

eval 'use Test::Pod::Coverage 1.00;';
if ($@) {
    plan skip_all => 'Test::Pod::Coverage 1.00 required for testing POD coverage';
} else {
    plan tests => 1;
}

ok(1, q(use "Build testpod" for this test));

