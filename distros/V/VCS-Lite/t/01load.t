#!/usr/bin/perl -w
use strict;

use Test::More tests => 2;

BEGIN {
	use_ok( 'VCS::Lite' );
	use_ok( 'VCS::Lite::Delta' );
}
