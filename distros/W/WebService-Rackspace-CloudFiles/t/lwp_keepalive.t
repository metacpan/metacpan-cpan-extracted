#!perl
use strict;
use warnings;
use Test::More tests => 6;
use LWP;
use WebService::Rackspace::CloudFiles::ConnCache;
 
my $ua = LWP::UserAgent->new;
$ua->conn_cache(
    WebService::Rackspace::CloudFiles::ConnCache->new(
        total_capacity          => 10,
        max_keep_alive_requests => 2,
    )
);
 
my $response = $ua->get('http://search.cpan.org/');
like( $response->header('Content-Type'), qr{text/html} );
is( $response->header('Client-Response-Num'), 1 );
 
$response = $ua->get('http://search.cpan.org/');
like( $response->header('Content-Type'), qr{text/html} );
is( $response->header('Client-Response-Num'), 2 );
 
$response = $ua->get('http://search.cpan.org/');
like( $response->header('Content-Type'), qr{text/html} );
is( $response->header('Client-Response-Num'), 1 );
