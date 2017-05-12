#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Win32::Sound' ) || print "Bail out!\n";
}

diag( "Testing Win32::Sound $Win32::Sound::VERSION, Perl $], $^X" );
