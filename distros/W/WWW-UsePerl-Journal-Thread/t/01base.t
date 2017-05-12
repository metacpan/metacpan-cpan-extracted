#!/usr/bin/perl -w
use strict;

#########################

use Test::More tests => 2;

BEGIN {
	use_ok( 'WWW::UsePerl::Journal::Comment' );
	use_ok( 'WWW::UsePerl::Journal::Thread' );
}

#########################

