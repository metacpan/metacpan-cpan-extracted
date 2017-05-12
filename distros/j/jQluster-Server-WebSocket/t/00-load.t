use 5.006;
use strict;
use warnings;
use Test::More;
 
plan tests => 2;
 
BEGIN {
    use_ok( 'jQluster::Server::WebSocket' );
    use_ok("jQluster::Server");
}
 
diag( "Testing jQluster::Server::WebSocket $jQluster::Server::WebSocket::VERSION, Perl $], $^X" );
