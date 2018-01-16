use Test::More;
use Test::Fatal;

use strict;
use warnings;

BEGIN { use_ok("Zonemaster::LDNS")}

SKIP: {
    skip 'no network', 2 unless $ENV{TEST_WITH_NETWORK};

    my $s = Zonemaster::LDNS->new( '8.8.8.8' );
    isa_ok( $s, 'Zonemaster::LDNS' );
    like( exception { $s->query( 'xx--example..', 'A' ) }, qr/Invalid domain name: xx--example../, 'Died on invalid name');
}

done_testing;
