use Test::More tests => 2;

BEGIN {
    use lib './lib';
    use WebService::Uptrack;
    my( $uptrack ) = WebService::Uptrack->new( credentials => { user => 'foo', key => 'bar' } );
    my( $json ) = $uptrack->_json;
    ok( defined( $json ) );
    ok( $json->isa( 'JSON::XS' ) );
}

diag( "Test initialization of _json" );
