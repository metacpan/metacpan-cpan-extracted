#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Text::ASCIIPipe' ) || print "Bail out!\n";
}

diag( "Testing Text::ASCIIPipe $Text::ASCIIPipe::VERSION, Perl $], $^X" );
