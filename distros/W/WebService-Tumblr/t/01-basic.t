#!/usr/bin/env perl
use strict;
use warnings;
use Test::Most;

use WebService::Tumblr;
use Try::Tiny;

my ( $tumblr, $dispatch, $request, $response, $content );

sub request (&) {
    my $code = shift;
    try {
        $code->();
    }
    catch {
        diag $tumblr->error_result->request->as_string;
        diag $tumblr->error_result->response->as_string;
        die $_[0];
    };
}

$tumblr = WebService::Tumblr->new( url => 'rokekr' );
$tumblr->identity( 'rokekr+tumblr@gmail.com', 'tumblrtumblr' );

ok( $tumblr );
is( $tumblr->url, 'http://rokekr.tumblr.com' );
is( $tumblr->name, 'rokekr' );

$tumblr->url( 'xyzzy.tumblr.com' );
is( $tumblr->url, 'http://xyzzy.tumblr.com' );
is( $tumblr->name, 'xyzzy' );

$tumblr->name( 'rokekr-tumblr' );
is( $tumblr->url, 'http://rokekr-tumblr.tumblr.com' );
is( $tumblr->name, 'rokekr-tumblr' );

$dispatch = $tumblr->posts;
is( $dispatch->request->as_string, "GET http://rokekr-tumblr.tumblr.com/api/read\n\n" );

$dispatch = $tumblr->write;
is( $dispatch->method, 'POST' );
$request = $dispatch->request->as_string;
like( $request, qr!^POST https://www.tumblr.com/api/write! );
like( $request, qr!Content-Length: \d{1,}! );

use WebService::Tumblr::Dispatch;
use WebService::Tumblr::Result;

done_testing;

__END__

$dispatch = $tumblr->posts( url => 'rokekr' );
diag $dispatch->response->as_string;

ok( $dispatch );

$dispatch = $tumblr->authenticate;
diag $dispatch->response->as_string;

#request { $content = $tumblr->pages };

#$tumblr->blog( 'rokekr' );
#is( $tumblr->blog, 'http://rokekr.tumblr.com' );

#request { $content = $tumblr->authenticate };
#ok( $content );
#explain( $content );

#request { $content = $tumblr->posts };
#ok( $content );
#explain( $content );

#request { $content = $tumblr->pages };
#ok( $content );
#explain( $content );

done_testing;


