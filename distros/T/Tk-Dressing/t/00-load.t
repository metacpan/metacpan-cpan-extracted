#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Tk::Dressing' ) || print "Bail out!
";
}

diag( "Testing Tk::Dressing $Tk::Dressing::VERSION, Perl $], $^X" );
