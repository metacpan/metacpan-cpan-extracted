use ExtUtils::testlib;

use strict;
use warnings;

use Win32::GlobalHotkey;

use Test::More tests => 1;


my $hk = Win32::GlobalHotkey->new( warn => sub { die 'test: ' . $_[0] } );


# warn - wrong key
eval {
	$hk->PrepareHotkey( vkey => '+', modifier =>  Win32::GlobalHotkey::MOD_ALT, cb => sub{ print 'ALT-B', "\n" } );
};

if ( substr( $@, 0, 4 ) eq 'test' ) {
	pass( 'standard' );
} else {
	fail( 'standard' );
}


