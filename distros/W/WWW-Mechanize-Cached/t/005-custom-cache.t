use strict;
use warnings FATAL => 'all';

use Test::More;
use Test::RequiresInternet ( 'www.wikipedia.com' => 443 );
use WWW::Mechanize::Cached ();

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
use constant URL  => 'https://www.wikipedia.org';
use constant SITE => 'Wikipedia';

use lib 't';
use TestCache;

my $SITE = SITE();

my $cache = TestCache->new();
isa_ok( $cache, 'TestCache' );

my $mech = WWW::Mechanize::Cached->new(
    cache          => $cache,
    autocheck      => 0,
    _verbose_dwarn => 1
);
isa_ok( $mech, 'WWW::Mechanize::Cached' );

my $first  = $mech->get(URL);
my $second = $mech->get(URL);
my $third  = $mech->get(URL);

SKIP: {
    skip "cannot connect to $SITE", 1 unless $mech->success;
    is( $third->content, "DUMMY", "Went thru my dummy cache" );
}

done_testing;
