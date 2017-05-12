use ExtUtils::testlib;

use strict;
use warnings;

use Win32::GlobalHotkey;


use Test::More tests => 4;

my $hk = Win32::GlobalHotkey->new;

is( $hk->GetConstant( 'MOD_ALT' )    , Win32::GlobalHotkey::MOD_ALT );
is( $hk->GetConstant( 'MOD_CONTROL' ), Win32::GlobalHotkey::MOD_CONTROL );
is( $hk->GetConstant( 'MOD_WIN' )    , Win32::GlobalHotkey::MOD_WIN );
is( $hk->GetConstant( 'MOD_SHIFT' )  , Win32::GlobalHotkey::MOD_SHIFT );

1;