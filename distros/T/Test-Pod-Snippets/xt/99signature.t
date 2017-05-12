use Test::More;

if( eval q{use Test::Signature; 1;} ) {
    plan tests => 1;
}
else {
    plan skip_all => 'Test::Signature required to test SIGNATURE';
}

signature_ok();
