#!perl

use Test::More tests => 12;

use strict;
use warnings;

use WWW::Mechanize::CGI;

my $mech = WWW::Mechanize::CGI->new;
$mech->env( DOCUMENT_ROOT => '/export/www/myapp' );
$mech->cgi_application('t/cgi-bin/script.cgi');

{
    my $response = $mech->get('http://localhost/');

    isa_ok( $response, 'HTTP::Response' );
    is( $response->code, 200, 'Response Code' );
    is( $response->message, 'OK', 'Response Message' );
    is( $response->protocol, 'HTTP/1.1', 'Response Protocol' );
    is( $response->content, '/export/www/myapp', 'Response Content' );
    is( $response->content_length, 17, 'Response Content-Length' );
    is( $response->content_type, 'text/plain', 'Response Content-Type' );
    is_deeply( [ $response->header('X-Field') ], [ 1, 2 ], 'Response Header X-Field' );
}

$mech->env( $mech->env, DIE => 1 );

{
    my $response = $mech->get('http://localhost/');

    isa_ok( $response, 'HTTP::Response' );
    is( $response->code, 500, 'Response Code' );
    is( $response->message, 'Internal Server Error', 'Response Message' );
    like( $response->header('X-Error'), qr/^Application .+ exited with value: 255/, 'Response Error Message' );
}
