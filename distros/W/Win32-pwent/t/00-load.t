#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Win32::pwent' ) || print "Bail out!
";
}

diag( "Testing Win32::pwent $Win32::pwent::VERSION, Perl $], $^X" );
