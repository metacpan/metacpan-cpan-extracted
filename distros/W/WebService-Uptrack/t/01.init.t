use Test::More tests => 2;

BEGIN {
    use lib './lib';
    use WebService::Uptrack;
    my( $uptrack ) = WebService::Uptrack->new( credentials => { user => 'foo', key => 'bar' } );
    ok( defined( $uptrack ) );
    ok( $uptrack->isa( 'WebService::Uptrack' ) );
}

diag( "Instantiating WebService::Uptrack $WebService::Uptrack::VERSION" );
