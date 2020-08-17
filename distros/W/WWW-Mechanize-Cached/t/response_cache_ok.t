use strict;
use warnings;

use HTTP::Response ();
use Test::More;
use WWW::Mechanize::Cached ();

my $mech = WWW::Mechanize::Cached->new;

my $res = HTTP::Response->new(200);
{
    my $h = HTTP::Headers->new;
    $h->header( 'Client-Transfer-Encoding' => 'chunked' );

    ok(
        $mech->_response_cache_ok( $res, $h ),
        'chunked Client-Transfer-Encoding'
    );
}

{
    my $h = HTTP::Headers->new;
    $h->header( 'Client-Transfer-Encoding' => 'chunked' );
    $h->push_header( 'Client-Transfer-Encoding' => 'foo' );

    ok(
        $mech->_response_cache_ok( $res, $h ),
        'chunked Client-Transfer-Encoding'
    );
}

{
    my $h = HTTP::Headers->new;
    $h->header( 'Client-Transfer-Encoding' => 'chunky' );
    ok(
        !$mech->_response_cache_ok( $res, $h ),
        'chunky Client-Transfer-Encoding'
    );
}

done_testing();
