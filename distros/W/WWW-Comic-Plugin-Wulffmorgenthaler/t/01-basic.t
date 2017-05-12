#!perl

use strict;
use WWW::Comic;
use Test::More tests => 3;

BEGIN {
	use_ok( 'WWW::Comic::Plugin::Wulffmorgenthaler' );
}


my $wc = new WWW::Comic;
my $strip_url = $wc->strip_url( comic => 'wulffmorgenthaler' );

ok($strip_url, 'Found a strip URL');
like($strip_url, qr/http:/, 'Strip URL looks vaguely sane');


