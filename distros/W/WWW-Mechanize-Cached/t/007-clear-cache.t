#!perl

use strict;
use warnings FATAL => 'all';

use Test::More tests => 13;

use constant {
    ADDRESS           => 'wikipedia.org',
    DIFFERENT_ADDRESS => 'en.wikipedia.org',
    SCHEME            => 'https://',
};

use Test::RequiresInternet (ADDRESS) => 443,
    (DIFFERENT_ADDRESS) => 443;

use WWW::Mechanize::Cached;

my $mech = WWW::Mechanize::Cached->new;

$mech->cache->clear;

ok( !defined $mech->is_cached,               'no request so far' );
ok( !defined $mech->invalidate_last_request, "can't clear without request" );

SKIP: {

    $mech->get( SCHEME . ADDRESS );
    skip( "Can't get the page", 11 ) unless $mech->success;
    is( $mech->is_cached, 0, 'not yet cached' );

    ok( !defined $mech->invalidate_last_request, "can't clear non-cached" );

    # Getting the same page twice is sometimes not enough to cache it
    # (different referrer?)
    for ( 'maybe cached', 'cached' ) {
        $mech->get( SCHEME . ADDRESS );
        skip( "Can't get the page", 9 ) unless $mech->success;
        last if $mech->is_cached;
    }
    ok( $mech->is_cached, 'cached now' );

    is( $mech->invalidate_last_request, 0, 'cleared successfully' );
    is( $mech->is_cached,               0, 'no longer cached' );

    $mech->get( SCHEME . ADDRESS );
    skip( "Can't get the page", 6 ) unless $mech->success;
    ok( !$mech->is_cached, 'not cached yet' );

    # Make sure that retrieving a page from cache changes the
    # _last_request correctly.

    $mech->get( SCHEME . DIFFERENT_ADDRESS );
    skip( "Can't get the page", 5 ) unless $mech->success;
    ok( !$mech->is_cached, 'different page not cached' );

    $mech->get( SCHEME . DIFFERENT_ADDRESS );
    skip( "Can't get the page", 4 ) unless $mech->success;
    ok( $mech->is_cached, 'different page cached' );

    $mech->get( SCHEME . ADDRESS );
    skip( "Can't get the page", 3 ) unless $mech->success;
    ok( $mech->is_cached, 'original page still cached' );

    is( $mech->invalidate_last_request, 0, 'cache cleared' );

    $mech->get( SCHEME . ADDRESS );
    skip( "Can't get the page", 1 ) unless $mech->success;
    ok( !$mech->is_cached, 'cleared after different page' );
}

done_testing;
