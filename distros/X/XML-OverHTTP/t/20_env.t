# ----------------------------------------------------------------
    use strict;
	use Test::More;
    require 't/MyAPI_env.pm.testing';
# ----------------------------------------------------------------
SKIP: {
    eval { require HTTP::Lite; } unless defined $HTTP::Lite::VERSION;
    eval { require LWP::UserAgent; } unless defined $LWP::UserAgent::VERSION;
	if ( ! $HTTP::Lite::VERSION && ! $LWP::UserAgent::VERSION ) {
	    plan skip_all => 'Both of HTTP::Lite and LWP::UserAgent are not loaded.';
	}
    if ( ! defined $ENV{MORE_TESTS} ) {
        plan skip_all => 'define $MORE_TESTS to test this.';
    }
    plan tests => 20;

    my $api = MyAPI_env::GET->new();
    my $ref = ref $api;
    ok( $ref, "new - $ref" );

    $api->add_param( four => 4 );
    $api->treepp->set( user_agent => $0 );
    $api->request();

    my $tree = $api->tree;
    ok( ref $tree, 'tree' );
    my $xml = $api->xml;
    like( $xml, qr/<\?xml/, 'xml decl' );
    my $code = $api->code;
    is( $code, '200', 'code' );

    my $query = $api->root->{QUERY_STRING};
    like( $query, qr/one=1/, "1 default_param" );
    like( $query, qr/four=4/, "4 add_param" );

    my $agent = $api->root->{HTTP_USER_AGENT};
    like( $agent, qr/\Q$0\E/, "User-Agent: $0" );

    my $err = $api->is_error();
    ok( ! $err, 'no error' );
}
# ----------------------------------------------------------------
{
    my $api = MyAPI_env::POST->new();

    my $ref = ref $api;
    ok( $ref, "new - $ref" );
    $api->treepp->set( user_agent => $0 );
    $api->request();

    my $tree = $api->tree;
    ok( ref $tree, 'tree' );
    my $xml = $api->xml;
    like( $xml, qr/<\?xml/, 'xml decl' );
    my $code = $api->code;
    is( $code, '200', 'code' );

    my $root = $api->root;
    is( ref $root, 'MyElement::env', 'MyElement::env' );

    my $agent = $api->root->{HTTP_USER_AGENT};
    like( $agent, qr/\Q$0\E/, "User-Agent: $0" );

    my $addr = $api->root->{SERVER_ADDR};
    my $port = $api->root->{SERVER_PORT};
    ok( UNIVERSAL::isa( $addr, 'ARRAY' ), 'force_array - SERVER_ADDR' );
    ok( UNIVERSAL::isa( $port, 'HASH' ), 'force_hash - SERVER_PORT' );
    is( ref $port, 'MyElement::SERVER_PORT', 'MyElement::SERVER_PORT' );

    my $err = $api->is_error();
    ok( ! $err, 'no error' );
}
# ----------------------------------------------------------------
{
    my $api = MyAPI_env::Error->new();
    my $ref = ref $api;
    ok( $ref, "new - $ref" );
    $api->request();
    my $err = $api->is_error();
    ok( $err, 'error' );
}
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------
