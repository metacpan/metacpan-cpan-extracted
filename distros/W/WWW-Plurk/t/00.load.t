use Test::More tests => 3;

BEGIN {
    use_ok( 'WWW::Plurk' );
    use_ok( 'WWW::Plurk::Friend' );
    use_ok( 'WWW::Plurk::Message' );
}

diag( "Testing WWW::Plurk $WWW::Plurk::VERSION" );
