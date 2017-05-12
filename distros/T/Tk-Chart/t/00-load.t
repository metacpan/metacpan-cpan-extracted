#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Tk::Chart' ) || print "Bail out!
";
}

diag( "Testing Tk::Chart $Tk::Chart::VERSION, Perl $], $^X" );
