#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Tk::ColoredButton' ) || print "Bail out!
";
}

diag( "Testing Tk::ColoredButton $Tk::ColoredButton::VERSION, Perl $], $^X" );
