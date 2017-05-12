use Test::More tests => 2;

BEGIN {
    use lib './lib';
    use WebService::Uptrack;
    my( $uptrack ) = WebService::Uptrack->new( credentials => { user => 'foo', key => 'bar' } );
    my( $ua ) = $uptrack->_ua;
    ok( defined( $ua ) );
    ok( $ua->isa( 'LWP::UserAgent' ) );
}

diag( "Test initialization of _ua" );
