#! /usr/bin/perl
#---------------------------------------------------------------------
# 00-load.t
#---------------------------------------------------------------------

use Test::More tests => 1;

BEGIN {
use_ok( 'Text::Wrapper' );
}

diag( "Testing Text::Wrapper $Text::Wrapper::VERSION" );
