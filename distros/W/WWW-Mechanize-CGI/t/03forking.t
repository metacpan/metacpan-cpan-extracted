#!perl

use strict;
use warnings;

use Config;
use Test::More;
use WWW::Mechanize::CGI;

unless ( $Config{d_fork} ) {
    plan skip_all => 'This test requires a plattform that supports fork()';
}

plan tests => 5;

my $mech = WWW::Mechanize::CGI->new;
$mech->fork(1);
$mech->cgi( sub {
    print "Content-Type: text/plain\n";
    print "Status: 200\n";
    print "\n";
} );

{
    my $response = $mech->get('http://localhost/');
    isa_ok( $response, 'HTTP::Response' );
    is( $response->code, 200, 'Response Code' );
}

$mech->cgi( sub { die 'oooups'; } );

{
    my $response = $mech->get('http://localhost/');
    isa_ok( $response, 'HTTP::Response' );
    is( $response->code, 500, 'Response Code' );
    like( $response->header('X-Error'), qr/^oooups/, 'Response Error Message' );
}
