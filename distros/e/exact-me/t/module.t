use Test::Most;

BEGIN {
    use_ok( 'exact', 'me', 'noautoclean' );
}

lives_ok( sub { me() }, 'me()' );
lives_ok( sub { me('../path/to/something') }, 'me("../path/to/something")' );
lives_ok( sub { me('path/to/something') }, 'me("path/to/something")' );

done_testing();
