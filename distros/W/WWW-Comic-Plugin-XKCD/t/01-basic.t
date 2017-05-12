#!perl

use strict;
use WWW::Comic;
use Test::More tests => 1;

BEGIN {
	use_ok( 'WWW::Comic::Plugin::XKCD' );
}


my $wc = new WWW::Comic;

diag("strip is at: " . $wc->strip_url( comic => 'xkcd' ));

