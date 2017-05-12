#!perl

###

use strict;
use warnings;
use Test::More tests => 18;
use WWW::RaptureReady;
ok(1); # If we made it this far, we're ok.

my $local_good = "t/rap2.html";

###

my $rr = WWW::RaptureReady->new;
ok($rr);
isa_ok( $rr, "WWW::RaptureReady" );

###

ok( $rr->url );
is( $rr->url, "http://www.raptureready.com/rap2.html" );
ok( $rr->url($local_good) );
is( $rr->url, "file:${local_good}" );
ok( $rr->url( "file:${local_good}" ) );
is( $rr->url, "file:${local_good}" );

###

ok( $rr->url( "file:${local_good}" ) );
ok( $rr->fetch );

###

ok( $rr->index );
like( $rr->index, qr/^\d+$/ );
is( $rr->index, 170 );

###

like( $rr->change, qr/^[+\-]?\d+$/ );
is( $rr->change, '0' );

###

ok( $rr->updated );
is( $rr->updated, 'Jul 12, 2010' );


###

