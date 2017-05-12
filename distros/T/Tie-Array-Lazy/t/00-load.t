#!perl -T
#
# $Id: 00-load.t,v 0.1 2007/05/26 17:54:19 dankogai Exp $
#
use strict;
use warnings;
use Test::More tests => 2;

BEGIN {
	use_ok( 'Tie::Array::Lazy' );
	use_ok( 'Tie::Array::Lazier' );
}

diag( "Testing Tie::Array::Lazy $Tie::Array::Lazy::VERSION, Perl $], $^X" );
