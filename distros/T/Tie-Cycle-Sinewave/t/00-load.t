# 00-load.t
#
# basic tests for Tie::Cycle::Sinewave
#
# Copyright (c) 2005-2007 David Landgren

use Test::More tests => 1;

BEGIN {
    use_ok( 'Tie::Cycle::Sinewave' );
}

diag( "testing Tie::Cycle::Sinewave $Tie::Cycle::Sinewave::VERSION" );
