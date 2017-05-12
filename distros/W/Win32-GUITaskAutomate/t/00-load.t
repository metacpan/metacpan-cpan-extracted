#!perl

use Test::More tests => 4;

BEGIN {
    SKIP: {
        skip('This module is for Windows; bailing out', 4)
            unless $^O eq 'MSWin32';

        use_ok('Carp');
        use_ok('Win32::GUIRobot');
        use_ok('Win32::Clipboard');
            use_ok( 'Win32::GUITaskAutomate' );
    }
}

diag( 'Testing Win32::GUITaskAutomate '
    . ( $Win32::GUITaskAutomate::VERSION || '[VERSION UNKNOWN]' )
    . ', Perl $], $^X'
);
