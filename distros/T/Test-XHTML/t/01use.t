#!/usr/bin/perl -w
use strict;

use Test::More tests => 4;

BEGIN {
	use_ok( 'Test::XHTML' );
	use_ok( 'Test::XHTML::Valid' );
	use_ok( 'Test::XHTML::WAI' );
	use_ok( 'Test::XHTML::Critic' );
}
