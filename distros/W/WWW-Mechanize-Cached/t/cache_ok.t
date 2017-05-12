use strict;
use warnings;

use HTTP::Request;
use Test::More;
use WWW::Mechanize::Cached;

my $mech = WWW::Mechanize::Cached->new;

my $response = HTTP::Response->new('200');

cmp_ok( $mech->positive_cache, '==', 1, "positive cache is ON" );
ok( $mech->_cache_ok($response), "200 is always cachable" );
ok(
    !$mech->_cache_ok( HTTP::Response->new(404) ),
    "won't cache 404 when positive"
);

$mech->positive_cache(0);
ok( $mech->_cache_ok($response), "200 is cachable in negative cache" );
ok(
    $mech->_cache_ok( HTTP::Response->new(404) ),
    "will cache 404 when negative"
);

done_testing();
