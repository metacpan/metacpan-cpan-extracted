#!perl
use strict;
use warnings;
use lib 'lib';
use Test::More tests => 9;
use_ok('WWW::Mechanize::Timed');

my $ua = WWW::Mechanize::Timed->new();
isa_ok( $ua, 'WWW::Mechanize::Timed' );
cmp_ok( $ua->client_elapsed_time, '==', 0, "Elapsed timer not started" );

$ua->get("http://www.astray.com/");

my ( $a, $b, $c, $d );
ok( defined( $a = $ua->client_request_connect_time ) );
ok( defined( $b = $ua->client_request_transmit_time ) );
ok( defined( $c = $ua->client_response_server_time ) );
ok( defined( $d = $ua->client_response_receive_time ) );
cmp_ok(
    $ua->client_total_time, '==',
    $a + $b + $c + $d,
    "client_total_time correct"
);
cmp_ok( $ua->client_elapsed_time, '>', $ua->client_total_time,
    "client_elapsed_time > client_total_time" );

