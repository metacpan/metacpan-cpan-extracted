use Test::More;

diag( "Testing URL::Social $URL::Social::VERSION, Perl $], $^X" );

BEGIN {
    use_ok( 'URL::Social' );
}

done_testing;
