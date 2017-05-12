#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Umask::Local' ) || print "Bail out!
";
}

diag( "Testing Umask::Local $Umask::Local::VERSION, Perl $], $^X" );
