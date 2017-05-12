#!/usr/bin/perl -w
use strict;

use Test::More;

BEGIN {
    # Skip if doing a regular install
    plan skip_all => "Author tests not required for installation"
        unless ( $ENV{AUTOMATED_TESTING} );

	eval	{ require Test::Distribution; };
	if($@)	{ plan skip_all => 'Test::Distribution not installed'; }
	else	{ import Test::Distribution; }
}
