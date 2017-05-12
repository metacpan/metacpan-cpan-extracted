#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Tk::DirSelect' ) || print "Bail out!
";
}

diag( "Testing Tk::DirSelect $Tk::DirSelect::VERSION, Perl $], $^X" );
