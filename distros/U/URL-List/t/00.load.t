use Test::More;

diag( "Testing URL::List $URL::List::VERSION, Perl $]" );

BEGIN {
    use_ok( "URL::List" );
}

done_testing;
