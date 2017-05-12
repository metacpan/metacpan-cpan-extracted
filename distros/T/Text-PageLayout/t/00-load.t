#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Text::PageLayout' ) || print "Bail out!\n";
}

diag( "Testing Text::PageLayout $Text::PageLayout::VERSION, Perl $], $^X" );
