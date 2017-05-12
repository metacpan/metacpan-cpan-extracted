#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Tk::Canvas::Draw' ) || print "Bail out!
";
}

diag( "Testing Tk::Canvas::Draw $Tk::Canvas::Draw::VERSION, Perl $], $^X" );
