use Test::Most tests => 2;

BEGIN {
    use_ok( 'exact', 'noautoclean' );
}

throws_ok( sub { croak('test failure success') }, qr/^test failure success/, 'croak' );
