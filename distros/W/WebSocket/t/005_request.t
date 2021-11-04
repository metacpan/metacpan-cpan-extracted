#!/usr/bin/env perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use Test::More;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use_ok 'WebSocket::Request';
my $req = WebSocket::Request->new( debug => $DEBUG );
ok( !$req->is_done );
# ok( !defined( $req->parse( "foo\x0d\x0a" ) ) );
# ok( $req->error );
# is( $req->error => 'Wrong request line' );

# $req = Protocol::WebSocket::Request->new;
my $req_headers = <<EOT;
GET /chat HTTP/1.1
Upgrade: WebSocket
Connection: Upgrade
Origin: http://example.com
EOT
my $rv = $req->parse( $req_headers );
# diag( "Error parsing: ", $req->error ) if( !defined( $rv ) && $DEBUG );
# Host is missing
ok( !$rv, 'parse: missing Host header' );

local $WebSocket::Common::MAX_MESSAGE_SIZE = 1024;

$req = WebSocket::Request->new( debug => $DEBUG );
ok( !defined( $req->parse( 'x' x (1024 * 10) ) ) );
is( $req->error->message => 'Message is too long' );

done_testing();

__END__

