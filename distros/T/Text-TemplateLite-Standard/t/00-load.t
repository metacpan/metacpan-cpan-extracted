#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Text::TemplateLite::Standard' ) || print "Bail out!\n";
}

diag( "Testing Text::TemplateLite::Standard $Text::TemplateLite::Standard::VERSION, Perl $], $^X" );
