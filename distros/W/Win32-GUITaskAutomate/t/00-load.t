#!perl

use Test::More tests => 4;

BEGIN {
    use_ok('Carp');
    use_ok('Win32::GUIRobot');
    use_ok('Win32::Clipboard');
	use_ok( 'Win32::GUITaskAutomate' );
}

diag( "Testing Win32::GUITaskAutomate $Win32::GUITaskAutomate::VERSION, Perl $], $^X" );
