use Test::More tests => 1;

BEGIN {
    use_ok( 'Test::Effects' )
        or
    BAIL_OUT q{Test::Effects did not load successfully};
}

diag( "Testing Test::Effects $Test::Effects::VERSION" );
