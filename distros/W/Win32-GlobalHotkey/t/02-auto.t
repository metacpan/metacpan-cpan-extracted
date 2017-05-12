use ExtUtils::testlib;

use strict;
use warnings;

use threads;
use threads::shared;

use Win32::GlobalHotkey;

use Test::More;

BEGIN {
	eval 'use Win32::GuiTest';
	if( $@ ) {
		plan skip_all => 'Win32::GuiTest required for testing' 
	} else {
		plan tests => 3;
	}
}

my $c_pressed : shared = 0;
my $q_pressed : shared = 0;

eval {
	my $hk = Win32::GlobalHotkey->new;
	$hk->PrepareHotkey( vkey => 'C', modifier =>  Win32::GlobalHotkey::MOD_ALT, cb => sub{ $c_pressed = 1 } );
	$hk->PrepareHotkey( vkey => 'Q', modifier =>  Win32::GlobalHotkey::MOD_CONTROL |  Win32::GlobalHotkey::MOD_ALT, cb => sub{ $q_pressed = 1 } );
	$hk->StartEventLoop;
	
	Win32::GuiTest->import( qw( SendKeys ) );
	
	SendKeys( '%c' );
	SendKeys( '^%q' );
	
	$hk->StopEventLoop;
};

if ( $@ ) {
	fail 'execution';	
} else {
	pass 'execution';
}

ok( $c_pressed, 'test ALT-C' );
ok( $q_pressed, 'test CONTROL-ALT-Q' );

1; 
