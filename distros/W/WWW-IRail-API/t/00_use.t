use Test::More;

BEGIN { 
    use_ok( 'WWW::IRail::API' ); 
    use_ok( 'WWW::IRail::API::Client::LWP' ); 
    use_ok( 'WWW::IRail::API::Connections' ); 
    use_ok( 'WWW::IRail::API::Liveboard' ); 
    use_ok( 'WWW::IRail::API::Vehicle' ); 
    use_ok( 'WWW::IRail::API::Stations' ); 
}
require_ok( 'WWW::IRail::API' );
require_ok( 'WWW::IRail::API::Client::LWP' );
require_ok( 'WWW::IRail::API::Connections' );
require_ok( 'WWW::IRail::API::Liveboard' ); 
require_ok( 'WWW::IRail::API::Vehicle' ); 
require_ok( 'WWW::IRail::API::Stations' ); 

done_testing();

