use Test::More;

$ENV{ TEST_AUTHOR } and eval q{
    use Test::Signature;
    goto RUN_TESTS;
};

plan skip_all => $@
    ? 'Test::Signature not installed; skipping signature testing'
    : 'Set TEST_AUTHOR in your environment to enable these tests';

RUN_TESTS:

plan tests => 1;

signature_ok();
