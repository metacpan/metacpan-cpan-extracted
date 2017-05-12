#!/usr/bin/perl -w

use Test::More tests => 3;

use_ok( 'Wx::DialUpManager' );
is( &Wx::wxEVT_DIALUP_CONNECTED, &Wx::wxEVT_DIALUP_CONNECTED, '&Wx::wxEVT_DIALUP_CONNECTED ');
is( &Wx::wxEVT_DIALUP_DISCONNECTED, &Wx::wxEVT_DIALUP_DISCONNECTED, '&Wx::wxEVT_DIALUP_DISCONNECTED');
