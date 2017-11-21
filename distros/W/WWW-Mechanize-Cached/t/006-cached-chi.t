#!perl

use strict;
use warnings FATAL => 'all';

use Test::More;
use Test::Requires 'CHI';
use Test::RequiresInternet ( 'www.wikipedia.com' => 443 );

# Google is a poor choice for this set of tests, as the main page google.com redirects, and the page it redirects
# to specifies "do not cache", and doesn't return a content-length.
#
# curl -L -v www.google.com
#
#< HTTP/1.1 302 Found
#< Location: http://www.google.co.nz/
#
#> GET / HTTP/1.1
#> User-Agent: curl/7.24.0 (x86_64-pc-linux-gnu) libcurl/7.24.0 OpenSSL/1.0.0j zlib/1.2.5.1
#> Host: www.google.co.nz
#> Accept: */*
#>
#< HTTP/1.1 200 OK
#< Date: Wed, 23 May 2012 10:09:55 GMT
#< Expires: -1
#< Cache-Control: private, max-age=0
#

use constant URL  => 'https://www.wikipedia.org';
use constant SITE => 'Wikipedia';

BEGIN {
    use_ok('WWW::Mechanize::Cached');
}

my $SITE = SITE();
my $stashpage;
my $secs        = time;    # Handy string that will be different between runs
my $cache_parms = {
    driver             => "File",
    namespace          => "www-mechanize-cached-$secs",
    default_expires_in => "1d",
};

FIRST_CACHE: {
    my $cache = CHI->new( %{$cache_parms} );
    isa_ok( $cache, 'CHI::Driver' );

    my $mech
        = WWW::Mechanize::Cached->new( autocheck => 0, cache => $cache, );
    isa_ok( $mech, 'WWW::Mechanize::Cached' );

    ok( !defined( $mech->is_cached ), "No request status" );

    my $first_req = $mech->get(URL);
    my $first     = $first_req->content;
SKIP: {
        skip "cannot connect to $SITE", 6 unless $mech->success;
        ok( defined $mech->is_cached, "First request" );
        ok( !$mech->is_cached,        "should be NOT cached" );
        $stashpage = $first;

        my $second = $mech->get(URL)->content;
        ok( defined $mech->is_cached, "Second request" );
        ok( $mech->is_cached,         "should be cached" );

        sleep 3;    # 3 due to Referer header
        my $third = $mech->get(URL)->content;
        ok( $mech->is_cached, "Third request should be cached" );

        is( $second => $third, "Second and third match" );
    }
}

SECOND_CACHE: {
    my $cache = CHI->new( %{$cache_parms} );
    isa_ok( $cache, 'CHI::Driver' );

    my $mech = WWW::Mechanize::Cached->new( autocheck => 0, cache => $cache );
    isa_ok( $mech, 'WWW::Mechanize::Cached' );

    my $fourth = $mech->get(URL)->content;
SKIP: {
        skip "cannot connect to $SITE", 2 unless $mech->success;
        is_deeply(
            [ split /\n/, $fourth ],
            [ split /\n/, $stashpage ],
            "Fourth request matches..."
        );
        ok( $mech->is_cached, "... because it's from the same cache" );
    }
}

done_testing;
