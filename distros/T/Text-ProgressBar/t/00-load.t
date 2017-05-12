#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Text::ProgressBar' ) || print "Bail out!\n";
}

diag( "Testing Text::ProgressBar $Text::ProgressBar::VERSION, Perl $], $^X" );
