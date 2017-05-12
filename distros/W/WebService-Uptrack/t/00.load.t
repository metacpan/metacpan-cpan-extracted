use Test::More tests => 1;

BEGIN {
    use lib './lib';
    use_ok( 'WebService::Uptrack' );
}

diag( "Testing WebService::Uptrack $WebService::Uptrack::VERSION" );
